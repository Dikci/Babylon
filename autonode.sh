sudo apt update
sudo apt install -y curl git jq lz4 build-essential

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

babylond config set client chain-id bbn-test-3
babylond config set client keyring-backend test
babylond config set client node tcp://localhost:20657

echo -e "Your Node Name"
read NODENAME
babylond init "$NODENAME" --chain-id bbn-test-3

curl -L https://snapshots-testnet.nodejumper.io/babylon-testnet/genesis.json > $HOME/.babylond/config/genesis.json
curl -L https://snapshots-testnet.nodejumper.io/babylon-testnet/addrbook.json > $HOME/.babylond/config/addrbook.json

sed -i -e 's|^seeds =.|seeds = "8da45f9ff83b4f8dd45bbcb4f850999637fbfe3b@seed0.testnet.babylonchain.io:26656,4b1f8a774220ba1073a4e9f4881de218b8a49c99@seed1.testnet.babylonchain.io:26656,9cb1974618ddd541c9a4f4562b842b96ffaf1446@3.16.63.237:26656,03ce5e1b5be3c9a81517d415f65378943996c864@18.207.168.204:26656,a5fabac19c732bf7d814cf22e7ffc23113dc9606@34.238.169.221:26656,ade4d8bc8cbe014af6ebdf3cb7b1e9ad36f412c0@testnet-seeds.polkachu.com:20656,798836777efb5555cfb940129e2073b44f9117e5@141.94.143.203:55706,86e9a68f0fd82d6d711aa20cc2083c836fb8c083@222.106.187.14:56000,326fee158e9e24a208e53f6703c076e1465e739d@babylon-testnet.cosmos-spaces.zone:26659,5e02bb2c9a644afae6109bf2c264d356fad27618@15.165.166.210:26656"|' $HOME/.babylond/config/config.toml

sed -i -e 's|^minimum-gas-prices =.|minimum-gas-prices = "0.00001ubbn"|' $HOME/.babylond/config/app.toml

sed -i
-e 's|^pruning =.|pruning = "custom"|'
-e 's|^pruning-keep-recent =.|pruning-keep-recent = "100"|'
-e 's|^pruning-interval =.|pruning-interval = "17"|'
$HOME/.babylond/config/app.toml

sed -i 's|^network =.|network = "signet"|g' $HOME/.babylond/config/app.toml

PEERS=8ccc36c80dc65031d5bc98e253b5eeab589ff82f@138.201.226.248:26656,5f0d6af642835b9d321529e4b8149a95280d5255@95.216.33.139:20656,4186822c72a578af7f9066e3b9248856bcb9f3f9@65.109.33.26:46656,d968bf54d4005796d77ef54d032aa258c73d29ea@81.27.244.79:26656,f844cccb9f0f3c286141ba87a2efa1801b8aaf82@88.99.65.115:20656,1d777050a95194fc78f4c38661cef13d00ac3fa9@213.199.33.123:26656,26cb133489436035829b6920e89105046eccc841@178.63.95.125:26656,a055973cd2d903b6909376b8f923c845213ce50e@190.3.117.147:16456,55dd38c8a8e2f6967d436163b002b8beb43a6b1f@164.68.125.55:26656,a0bbd407692bf14b45f08e76093c4a1f03d1f6e4@65.108.78.116:16456,ab58d45ea83a5aabc57851b38771747bfe423f65@184.174.37.13:26656,0defb22f46cead0680ad79fedfa87026690e0307@162.19.18.137:35622,f66ce47dd9942111e22e174fbdb5ed85dc626cb9@65.109.104.111:26656,fa46eaf073a665f52d727b7e5e57fb49ccf4f6df@149.102.158.188:20656,a9bee857f77101b8471ca6e21231bc03b458c7c4@62.171.136.144:26656,d318280bdd4732e1386492dd1067aad228854e8b@154.53.51.114:26656,9a13b2632c3ff64624e0b3bbba65307bbbeeec3a@37.60.229.6:20656,8090c9b00331e4cfa9dd99e51c86c036fb163659@203.113.174.180:26656,8b40f51bcfd600278edcb9fd666f52b490b0c67c@154.26.137.255:26656,e479870a50174327351b88998aff36d69350d0fc@168.119.213.113:16456
sed -i 's|^persistent_peers =.|persistent_peers = "'$PEERS'"|' $HOME/.babylond/config/config.toml

curl "https://snapshots-testnet.nodejumper.io/babylon-testnet/babylon-testnet_latest.tar.lz4" | lz4 -dc - | tar -xf - -C "$HOME/.babylond"

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
