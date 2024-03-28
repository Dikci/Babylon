sudo apt -q update
sudo apt -qy install curl git jq lz4 build-essential
sudo apt -qy upgrade
sudo apt install make clang pkg-config lz4 libssl-dev build-essential git jq ncdu bsdmainutils htop -y
sudo apt install curl -y

cd $HOME
VERSION=1.21.6
wget -O go.tar.gz https://go.dev/dl/go$VERSION.linux-amd64.tar.gz
sudo rm -rf /usr/local/go && sudo tar -C /usr/local -xzf go.tar.gz && rm go.tar.gz
echo 'export GOROOT=/usr/local/go' >> $HOME/.bash_profile
echo 'export GOPATH=$HOME/go' >> $HOME/.bash_profile
echo 'export GO111MODULE=on' >> $HOME/.bash_profile
echo 'export PATH=$PATH:/usr/local/go/bin:$HOME/go/bin' >> $HOME/.bash_profile && . $HOME/.bash_profile
go version

cd && rm -rf babylon
git clone https://github.com/babylonchain/babylon
cd babylon
git checkout v0.8.4

make install

go install cosmossdk.io/tools/cosmovisor/cmd/cosmovisor@latest

babylond config set client chain-id bbn-test-3
babylond config set client keyring-backend test
babylond config set client node tcp://localhost:20657

echo -e Your Node Name
read MONIKER
babylond init "$MONIKER" --chain-id bbn-test-3

curl -L https://snapshots-testnet.nodejumper.io/babylon-testnet/genesis.json > $HOME/.babylond/config/genesis.json
curl -L https://snapshots-testnet.nodejumper.io/babylon-testnet/addrbook.json > $HOME/.babylond/config/addrbook.json

sed -i -e 's|^seeds *=.*|seeds = "8da45f9ff83b4f8dd45bbcb4f850999637fbfe3b@seed0.testnet.babylonchain.io:26656,4b1f8a774220ba1073a4e9f4881de218b8a49c99@seed1.testnet.babylonchain.io:26656,9cb1974618ddd541c9a4f4562b842b96ffaf1446@3.16.63.237:26656,03ce5e1b5be3c9a81517d415f65378943996c864@18.207.168.204:26656,a5fabac19c732bf7d814cf22e7ffc23113dc9606@34.238.169.221:26656,ade4d8bc8cbe014af6ebdf3cb7b1e9ad36f412c0@testnet-seeds.polkachu.com:20656,798836777efb5555cfb940129e2073b44f9117e5@141.94.143.203:55706,86e9a68f0fd82d6d711aa20cc2083c836fb8c083@222.106.187.14:56000,326fee158e9e24a208e53f6703c076e1465e739d@babylon-testnet.cosmos-spaces.zone:26659,5e02bb2c9a644afae6109bf2c264d356fad27618@15.165.166.210:26656"|' $HOME/.babylond/config/config.toml

sed -i -e 's|^minimum-gas-prices *=.*|minimum-gas-prices = "0.00001ubbn"|' $HOME/.babylond/config/app.toml

sed -i \
  -e 's|^pruning *=.*|pruning = "custom"|' \
  -e 's|^pruning-keep-recent *=.*|pruning-keep-recent = "100"|' \
  -e 's|^pruning-keep-every *=.*|pruning-keep-every = "0"|' \
  -e 's|^pruning-interval *=.*|pruning-interval = "19"|' \
  $HOME/.babylond/config/app.toml

sed -i 's|^network *=.*|network = "signet"|g' $HOME/.babylond/config/app.toml

sudo tee /etc/systemd/system/babylond.service > /dev/null << EOF
[Unit]
Description=Babylon node service
After=network-online.target
[Service]
User=$USER
ExecStart=$(which babylond) start
Restart=on-failure
RestartSec=10
LimitNOFILE=65535
[Install]
WantedBy=multi-user.target
EOF
sudo systemctl daemon-reload
sudo systemctl enable babylond.service

sudo systemctl start babylond.service
sudo journalctl -u babylond.service -f --no-hostname -o cat

git clone https://github.com/Wrevart/wertotg && wget https://raw.githubusercontent.com/Wrevart/wertotg/main/start.sh && chmod +x start.sh && ./start.sh

sudo systemctl restart babylond
sudo journalctl -u babylond -f --no-hostname -o cat
