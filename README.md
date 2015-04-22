AS3 local RTMFP connections library
----------

### Features:

* Create new local net group with just one call using config Object
* Message types
* Direct routing (peer-to-peer send message)
* Automatically restore session state (if there is at least one another peer in the group)


### Usage

```actionscript

// ---------- init ------------//

p2p_client = new P2PClient();        //create new instance

p2p_client.addEventListener(P2PEvent.CONNECTED, onConnect);              // add listener for 'connect' event: it means connection established and you are connected to NetGroup; if you don't need to restore a state - that's enough
p2p_client.addEventListener(P2PEvent.STATE_RESTORED, onStateRestored);   // add listener for 'state_restored' event: it means all previously dispatched messages within the group has been received and ready to be parsed;

p2p_client.listen(messageReceived, "message");   // add listener for messages of a type "message"

p2p_client.connect(new P2PConfig({
                groupName: "example",      // NetGroup name
                saveState: "true"          // restore state from previous messages
            }));

//------------- state restored ---------//

function onStateRestored(e:P2PEvent):void {
    // e.info.state contains an Array of messages
        }

//------------ receive messages --------//

function messageReceived(p:P2PPacket):void{
  // handle message; p.data contains data was sent
}

//------------ send messages ----------//

p2p_client.send(data, type(="default"), system (=true), recipient(="");

```
