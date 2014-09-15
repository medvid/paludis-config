#!/usr/bin/env ruby
# vim: set sw=4 sts=4 et tw=80 :

require 'Paludis'
require 'rubygems'
require 'sqlite3'
require 'set'

include Paludis

Log.instance.log_level = Paludis::LogLevel::Warning
Log.instance.program_name = $0

generate_cache = true

ARGV.each_index do |idx|
    case ARGV[idx]
    when '--help'
        puts "Usage: " + $0 + " [options] search-index-dir"
        puts
        puts "Options:"
        puts "  --help    Display a help message"
        puts "  --no-gen  Don't generate a new cache"
        puts "  --version Display program version"
        exit 0

    when '--version'
        puts $0.to_s.split(/\//).last + " " + Paludis::Version.to_s
        exit 0

    when '--no-gen'
        generate_cache = false
end

if ARGV.length != 1
    if generate_cache == false and ARGV.length != 2
        puts "Please specify the location of the search index"
        exit 1
    end
end

def make_index( location )
    puts "Regenerating search index..."
    system( "cave", "manage-search-index", "-c", location )
    return location
end

def read_index( location, environment )
    return SQLite3::Database.new(
        location, :results_as_hash => true
    ).execute(
        "SELECT * FROM candidates"
    ).map { |row|
        {
            :spec => Paludis::parse_user_package_dep_spec( row['spec'], environment, []),
            :is_visible => row['is_visible'],
            :qpn => row['name'],
        }
    }
end

def parse_rows( packages )
    packages.each { |entry|
        unless entry[:spec].version_requirements.empty?
            entry[:version] = entry[:spec].version_requirements[0][:spec]
        end
        entry[:slot] = entry[:spec].slot_requirement.to_s
        entry[:repository] = entry[:spec].in_repository.to_s
    }
end

def mark_best( packages )
    packages.group_by { |entry| entry[:qpn] }.each_value.map { |specs|
        specs.select { |info|
            info[:repository].to_s != 'installed'
        }.select { |info|
            info[:repository].to_s != 'installed-accounts'
        }.select { |info|
            info[:repository].to_s != 'binary'
        }.reverse.sort { |a,b|
            a[:version] <=> b[:version]
        }.detect { |info|
            info[:is_visible] == 1
        }
    }.select { |info|
        not info.nil?
    }.each { |info|
        info[:is_best_visible] = 1
    }
end

def delta_package( old, new, results )
    results[:kept_packages] = SortedSet.new( old ) & SortedSet.new( new )
    results[:added_packages] = SortedSet.new( new ) - results[:kept_packages]
    results[:removed_packages] = SortedSet.new( old ) - results[:kept_packages]
end

def delta_slot( old, new, results )
    results[:changed_slots] = Hash.new()
    results[:kept_packages].each { |qpn|
        old_slots = SortedSet.new( old[qpn].map { |spec| spec[:slot] } )
        new_slots = SortedSet.new( new[qpn].map { |spec| spec[:slot] } )
        unless old_slots == new_slots
            results[:changed_slots][qpn] = {
               :added => new_slots - old_slots,
               :removed => old_slots - new_slots
            }
        end
    }
end

def delta_visibility( old, new, results )
    results[:best_visible] = Hash.new()
    results[:kept_packages].map { |qpn|
        entry = {
            :new => new[qpn].detect { |info| info[:is_best_visible] },
            :old => old[qpn].detect { |info| info[:is_best_visible] }
        }
        unless entry[:new].nil? and entry[:old].nil?
            results[:best_visible][qpn] = entry
        end
    }
    results[:became_visible] = SortedSet.new( results[:best_visible].each_key.select { |qpn| results[:best_visible][qpn][:old].nil? } )
    results[:became_invisible] = SortedSet.new( results[:best_visible].each_key.select { |qpn| results[:best_visible][qpn][:new].nil? } )
end

def delta_repo_ver( results )
    results[:repository_changed] = Hash.new()
    results[:best_version_changed] = Hash.new()

    results[:best_visible].each_key { |qpn|
        old = results[:best_visible][qpn][:old]
        new = results[:best_visible][qpn][:new]
        unless new.nil? or old.nil?
            if old[:repository] != new[:repository]
                results[:repository_changed][old[:qpn]] = { :old => old[:repository],
                                                  :new => new[:repository] }
            end
            if old[:version] != new[:version]
                results[:best_version_changed][old[:qpn]] = { :old => old[:version],
                                                    :new => new[:version] }
            end
        end
    }
end

def titled_list( title, list )
    unless list.empty?
        puts title
        list.each { |item| puts "\t" + item }
        puts
    end
end

def print_results( results )
    titled_list( "Packages added:", results[:added_packages] )
    titled_list( "Packages removed:", results[:removed_packages] )

    titled_list( "Packages which have become visible:", results[:became_visible] )
    titled_list( "Packages which are no longer visible:", results[:became_invisible] )

    unless results[:repository_changed].empty?
        puts "Packages whose repositories changed:"
        results[:repository_changed].each_key.sort.each { |qpn|
            puts "\t" + qpn
            puts "\t\told: " + results[:repository_changed][qpn][:old]
            puts "\t\tnew: " + results[:repository_changed][qpn][:new]
        }
        puts
    end

    unless results[:best_version_changed].empty?
        puts "Packages whose best visible version changed:"
        results[:best_version_changed].each_key.sort.each { |qpn|
            puts "\t" + qpn
            puts "\t\told: " + results[:best_version_changed][qpn][:old].to_s
            puts "\t\tnew: " + results[:best_version_changed][qpn][:new].to_s
        }
        puts
    end

    unless results[:changed_slots].empty?
        puts "Packages whose slots changed:"
        results[:changed_slots].each_key.sort.each { |qpn|
            puts "\t" + qpn
            unless results[:changed_slots][qpn][:added].empty?
                puts "\t\tadded: " + results[:changed_slots][qpn][:added].to_a.join( " " )
            end
            unless results[:changed_slots][qpn][:removed].empty?
                puts "\t\tremoved: " + results[:changed_slots][qpn][:removed].to_a.join( " " )
            end
        }
        puts
    end
end

def pivot_index( location )
    now = Time.new.to_i.to_s
    File.rename( location + "current", location + "old-" + now )
    File.exist?( location + "old" ) and File.unlink( location + "old" )
    File.symlink( location + "old-" + now, location + "old" )
    File.rename( location + "new", location + "current" )
    puts "Done regenerating search index" 
end

env = Paludis::PaludisEnvironment.new
results = Hash.new

index_location = ARGV.pop() + "/"

old = ''
new = ''

if generate_cache == true
    old = read_index( index_location + "current", env )
    new = read_index( make_index( index_location + "new" ), env )
else
    old = read_index( index_location + "old", env )
    new = read_index( index_location + "current", env )
end

parse_rows( old )
parse_rows( new )

mark_best( old )
mark_best( new )

delta_package(
    old.group_by { |entry| entry[:qpn] }.keys,
    new.group_by { |entry| entry[:qpn] }.keys,
    results
)

delta_slot(
    old.group_by { |entry| entry[:qpn] },
    new.group_by { |entry| entry[:qpn] },
    results
)

delta_visibility(
    old.group_by { |entry| entry[:qpn] },
    new.group_by { |entry| entry[:qpn] },
    results
)

delta_repo_ver( results )

print_results( results )

if generate_cache == true
    pivot_index( index_location )
end

exit( 0 )
end
