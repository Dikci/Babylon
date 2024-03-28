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

echo -e "Your Node Name"
read NODENAME
babylond init "$NODENAME" --chain-id bbn-test-3

curl -Ls https://snapshots.kjnodes.com/babylon-testnet/genesis.json > $HOME/.babylond/config/genesis.json
curl -Ls https://snapshots.kjnodes.com/babylon-testnet/addrbook.json > $HOME/.babylond/config/addrbook.json

sed -i -e 's|^seeds =.|seeds = "8da45f9ff83b4f8dd45bbcb4f850999637fbfe3b@seed0.testnet.babylonchain.io:26656,4b1f8a774220ba1073a4e9f4881de218b8a49c99@seed1.testnet.babylonchain.io:26656,9cb1974618ddd541c9a4f4562b842b96ffaf1446@3.16.63.237:26656,03ce5e1b5be3c9a81517d415f65378943996c864@18.207.168.204:26656,a5fabac19c732bf7d814cf22e7ffc23113dc9606@34.238.169.221:26656,ade4d8bc8cbe014af6ebdf3cb7b1e9ad36f412c0@testnet-seeds.polkachu.com:20656,798836777efb5555cfb940129e2073b44f9117e5@141.94.143.203:55706,86e9a68f0fd82d6d711aa20cc2083c836fb8c083@222.106.187.14:56000,326fee158e9e24a208e53f6703c076e1465e739d@babylon-testnet.cosmos-spaces.zone:26659,5e02bb2c9a644afae6109bf2c264d356fad27618@15.165.166.210:26656"|' $HOME/.babylond/config/config.toml

sed -i -e 's|^minimum-gas-prices =.|minimum-gas-prices = "0.00001ubbn"|' $HOME/.babylond/config/app.toml

sed -i 's|^network =.|network = "signet"|g' $HOME/.babylond/config/app.toml

PEERS="f21a213df689092f1e3b5064cb90000a2f501914@207.180.225.144:26656,9750b2eac3f3b7f344209098fdae2d4dcd91f426@5.189.170.197:26656,40ead08eb29d436197d5e9ed293aa33ad20cafba@213.199.36.50:26656,54300e49e61e1c8a65cc444b83cdd56559d5d9d3@173.212.202.142:26656,bd9b58b53cf202c552d9bc13a8f56d74780d3464@89.117.20.203:26656,ce0892fb43078fd208396dbd046570f4db29bdd4@77.221.153.26:26656,2af11b08ea816acb95d4de33c3de07a32c1cc801@82.208.20.66:26656,fe42bd77a39384ae4693ce874bfd203d0b934bd5@142.202.48.25:20656,0fdc5e41de89549f7a854ea160135a03dd4d104c@158.220.116.210:26656,d73a19b6a3a0e26364ef76152e42845895899478@109.199.121.195:20656,f0ff4ff0271f09b30777aecf984b2e3e9e9a84b4@109.199.121.187:26656,5e0cfe5a09137055834835339afa064b6f5c0631@37.60.231.248:26656,70782b85ab174e8f75e6ececf10ea6db1a0376cd@38.242.236.237:26656,e17ac3c34eb359a6737c922a303304a5cbeeff70@213.199.53.20:26656,93450701076aa1c5e31bcc0b2c2dc3682440a035@109.199.120.222:26656,22e5b0aa5f470cea22777f0cc5efba8fa74faf93@213.199.59.255:26656,efb4b5c0274eae783fc3061195eb190c09d932a8@109.123.236.193:26656,ab914850bda6f910eef9f33243f64f1efc18fc7b@158.220.85.38:26656,a80ab9adc2667ea9cfede5712e753edc9da256d7@45.10.154.240:26656,d9f8a85c8b56475e1574bf599df42fa029720694@173.212.250.45:26656"
sed -i 's|^persistent_peers *=.*|persistent_peers = "'$PEERS'"|' $HOME/.babylond/config/config.toml

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
