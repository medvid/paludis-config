# paludis-config

My Paludis configuration for Exherbo

Adjust repository paths:

    cd /var/db/paludis/repositories
    mv installed x86_64-pc-linux-gnu
    mkdir exndbam
    mv x86_64-pc-linux-gnu exndbam
    echo -e 'installed\npbin' > .ignore
    cd /etc
    mv paludis paludis-orig

Clone the repository:

    git clone https://github.com/medvid/paludis-config.git ~/dev/exherbo/paludis-config

Install all environments:

    ~/dev/exherbo/paludis-config/install.sh

Install specific environment:

    ~/dev/exherbo/paludis-config/homepc/install.sh

Select default environment:

    sudo ln -sT /etc/paludis-homepc /etc/paludis

To run cave in specific environment (/etc/paludis-xxx):

    cave -E :xxx ...

For example:

    cave -E :cubie ...
    cave -E :pinebook ...
