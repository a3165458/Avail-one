#官方方式安装并导入老钱包

#执行nohup 后台运行并输出logs

read -p "请输入您的12位钱包助记词：" SECRET_SEED_PHRASE
mkdir availd
cat > /root/availd/identity.toml <<EOF
avail_secret_seed_phrase = "$SECRET_SEED_PHRASE"
EOF

nohup bash -c 'curl -sL1 avail.sh | bash -s -- --network goldberg --identity /root/availd/identity.toml' > output.log 2>&1 &



#获取public key

cat output.log
