# nustool
Mac OSX / iOS Tool for bridging Nordic NUS (UART Service) to a TCP/IP port

## Use

1. Select the TCP/IP port you want in the text field. Default is 8889

2. Find the device you want to connect to by searching for its service UUID
or its User-Friendly name.  If the device is advertising it will appear
in the selection list

3. Select the device and hit "Connect" which will

- Connect to device's Nordic NUS (UART) Service over BLE

- Start serving a "telnet" (raw TCP/IP) service on the selected port

4. Using a terminal program like telnet, or putty, connect to the
server on the port to get console/uart access to the BLE device

