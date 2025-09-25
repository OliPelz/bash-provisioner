## Good to know
 
external binaries in here need to be included in PATH

```bash

export PATH=./include_bins/shunit2:./include_bins/bats:$PATH

```

## How to update external binaries

### shunit2

```bash

mkdir -p ./include_bins/shunit2
cd ./include_bins/shunit2
wget https://raw.githubusercontent.com/kward/shunit2/refs/heads/master/shunit2
chmod +x shunit2

```


### bats

```bash

BATS_VERSION=1.12.0
mkdir -p ./include_bins/bats
curl -L https://github.com/bats-core/bats-core/archive/refs/tags/v${BATS_VERSION}.tar.gz \
  | tar -xz --strip-components=1 -C ./include_bins/bats

```
