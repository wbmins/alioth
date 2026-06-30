PostmarketOS qcom-sm8250 alioth firmware, kernel, and device repository, 
facilitating customization of kernel parameters.

Add the following command
echo "https://wbmins.github.io/alioth/edge" | \
sudo tee -a /etc/apk/repositories && \
sudo rm /etc/apk/keys/pmos@local*.rsa.pub && \
sudo curl --output-dir /etc/apk/keys/ \
-O https://wbmins.github.io/alioth/edge/aarch64/pmos@mins.rsa.pub