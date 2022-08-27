# ERC20 Token and Inital Coin Offering
This is a smart contract written in solidity to create a new ERC20 Token which can be deployed on the Ethereum Test Network.
<br />
<br />
The second part of the code an initial coin offering which is a form of crowdfuntion to raise money to successfully deploy the new coin on the crypto-market.
<br />
<br />
This code can be run on any Solidity compiler (preferably Remix IDE).

<br />
 - The coin is generated as per standard
 - The ICO is not working as required
 - An investor can send an amount of ether, which is transferred to the admin of the contract
 - In return the investor should receive a specific amount of the token
 - However this is not working and I do not understand why
 - Initially I implemented a function in the coin called mint
 - This function allowed a user to send an amount of ether to the contract which in return gave the user an equivalent amount of ether back from the totalSupply.
 - The ether could then be withdrawn by the owner whenever he pleased
 - This code has been commented out in the file and its implementation can be seen clearly there
