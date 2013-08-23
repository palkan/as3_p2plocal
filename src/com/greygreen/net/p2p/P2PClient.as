/**
 * User: palkan
 * Date: 8/20/13
 * Time: 2:05 PM
 */
package com.greygreen.net.p2p {
import com.greygreen.net.p2p.events.P2PEvent;
import com.greygreen.net.p2p.model.P2PConfig;
import com.greygreen.net.p2p.model.P2PPacket;

import flash.errors.IllegalOperationError;
import flash.events.EventDispatcher;
import flash.events.NetStatusEvent;
import flash.net.GroupSpecifier;
import flash.net.NetConnection;
import flash.net.NetGroup;
import flash.net.NetGroupInfo;
import flash.utils.setTimeout;

import ru.teachbase.constants.NetConnectionStatusCodes;
import ru.teachbase.constants.NetGroupStatusCodes;
import ru.teachbase.utils.extensions.FuncObject;
import ru.teachbase.utils.shortcuts.debug;

/**
 *  Dispatches when NetConnection and NetGroup successfully connected.
 *
 *  @eventType com.greygreen.net.p2p.events.P2PEvent.CONNECTED
 */

[Event(type="com.greygreen.net.p2p.events.P2PEvent", name="p2p:connected")]

/**
 *  Dispatches when session state is restored.
 *
 *  @eventType com.greygreen.net.p2p.events.P2PEvent.STATE_RESTORED
 */

[Event(type="com.greygreen.net.p2p.events.P2PEvent", name="p2p:state_restored")]

/**
 *  Dispatches when session state restore proccess is failed.
 *
 *  @eventType com.greygreen.net.p2p.events.P2PEvent.STATE_RESTORE_FAILED
 */

[Event(type="com.greygreen.net.p2p.events.P2PEvent", name="p2p:state_restore_failed")]

/**
 *  Dispatches when some error occurred.
 *
 *  @eventType com.greygreen.net.p2p.events.P2PEvent.FAILED
 */

[Event(type="com.greygreen.net.p2p.events.P2PEvent", name="p2p:failed")]

/**
 *  Dispatches when NetConnection closed successfully (e.g. connection closing was intended).
 *
 *  @eventType com.greygreen.net.p2p.events.P2PEvent.CLOSED
 */

[Event(type="com.greygreen.net.p2p.events.P2PEvent", name="p2p:closed")]

/**
 *  Dispatches when new peer (actually, neighbor) connected to NetGroup.
 *
 *  @eventType com.greygreen.net.p2p.events.P2PEvent.PEER_CONNECTED
 */

[Event(type="com.greygreen.net.p2p.events.P2PEvent", name="p2p:peer_connected")]

/**
 *  Dispatches when peer disconnected.
 *
 *  @eventType com.greygreen.net.p2p.events.P2PEvent.PEER_DISCONNECTED
 */

[Event(type="com.greygreen.net.p2p.events.P2PEvent", name="p2p:peer_disconnected")]



/**
 *
 * P2PClient works with serverless RTMFP connections and handle such tasks as connecting to group, sending/receiving messages, data replication.
 *
 * It is possible to store all session messages in <code>mailbox</code> as replicated object (kinda history storage). Mailbox can be filled up with external data (e.g. you can store data somewhere else for backup).
 *
 * Messages are divided into two classes: <i>system</i> and <i>temporary</i>. Only system messages are stored in the mailbox.
 *
 * Every message also has a <i>type</i> (string identifier) which is used for separated message dispatching.
 *
 */

public class P2PClient extends EventDispatcher{

    private const RESTORE_MAX_TRIES:int = 3;

    private const connection:NetConnection = new NetConnection();
    private const listeners:FuncObject = new FuncObject();

    private var _mailbox:P2PMailbox;
    private var _group:NetGroup;

    private var _replicateState:Boolean = true;
    private var _restoreTries:int = 0;

    private var _config:P2PConfig;

    private var _receive:Boolean = false;

    private var _connected:Boolean = false;
    private var _disposed:Boolean = false;

    private var _neighborHasConnected:Boolean = false;

    /**
     *
     * Creates new P2PClient instance.
     */

    public function P2PClient(){
       new P2PPacket();
    }


    /**
     *
     * Creates new local RTMFP Connection.
     *
     * @param config
     *
     * @throws IllegalOperationError If client is already connected.
     */

    public function connect(config:P2PConfig):void{

        if(_disposed) return;

        if(_connected) throw new IllegalOperationError("P2PClient is already connected");

        _config = config;

        _replicateState = _config.saveState;

        _receive = !_config.saveState;

        connection.addEventListener(NetStatusEvent.NET_STATUS, connectionStatus);

        connection.connect("rtmfp:");

    }

    /**
     *
     * When <code>recipient</code> is provided uses <code>sendToNearest()</code> to send message.
     * Otherwise uses <code>post()</code>.
     *
     * Sending is disabled if on of the following:
     *
     * <li> - NetConnection or NetGroup is not connected;</li>
     * <li> - mailbox is enabled but not restored;</li>
     * <li> - <code>receive == false;</code></li>
     *
     * @param data
     * @param type
     * @param system
     * @param recipient Recipient peerID or empty string
     */

    public function send(data:*, type:String = "default", system:Boolean = true, recipient:String = ""):void{

        if(!_connected || !_receive || (_mailbox && !_mailbox.restored)) return;

        const packet:P2PPacket = new P2PPacket(type, data, connection.nearID, recipient, !recipient && system);

        if(!recipient){
            _group.post(packet);
            _mailbox && system && _mailbox.push(packet,true);
        }
        else _group.sendToNearest(packet,_group.convertPeerIDToGroupAddress(recipient));

    }


    /**
     *
     * Register new message listener.
     *
     * Listener must be a Function accepting one argument of a type <code>P2PPacket</code>.
     *
     * It is possible to register arbitrary number of listeners of one type.
     *
     * @param type
     * @param handler
     *
     * @see P2PPacket$
     */

    public function listen(handler:Function,type:String = "default"):void{
        if(_disposed) return;
        (handler is Function) && (listeners[type] = handler);
    }



    /**
     *
     * Unregister listener
     *
     * @param type
     * @param handler
     */


    public function unlisten(type:String, handler:Function):void{
        if(_disposed) return;
        listeners.deleteFromProperty(type,handler);
    }




    /**
     */


    protected function setupGroup():void{

        var groupspec:GroupSpecifier = new GroupSpecifier(_config.groupName);
        groupspec.postingEnabled = true;
        groupspec.routingEnabled = true;
        groupspec.ipMulticastMemberUpdatesEnabled = true;
        groupspec.addIPMulticastAddress(_config.ip);
        groupspec.objectReplicationEnabled = _config.saveState;

        _group = new NetGroup(connection,groupspec.groupspecWithAuthorizations());

        if(_config.saveState)
            _mailbox = new P2PMailbox(_group);

        _group.addEventListener(NetStatusEvent.NET_STATUS,connectionStatus);
    }

    /**
     *
     * @param packet
     */

    private function sendPacket(packet:P2PPacket):void{

        if(!packet) return;

        (listeners[packet.type] is Function) && listeners[packet.type].call(null,packet);
    }

    /**
     *
     * @param packet
     */

    private function handlePacket(packet:P2PPacket):void{

        if(!packet) return;

        _mailbox && packet.system && !_mailbox.restoreWaiting && _mailbox.push(packet);

        if(!_receive) return;

        var packetToSend:P2PPacket;

        if(!_mailbox || (_mailbox && !packet.system && _mailbox.restored))
            packetToSend = packet;
        else if(_mailbox.restored)
            packetToSend = _mailbox.next();

        sendPacket(packetToSend);
    }

    /**
     *
     * @param index
     */

    private function restoreState(index:Number = 0):void{
        debug("[restore] size of group: "+_group.neighborCount);
        if(!_group.neighborCount){
            _mailbox.restored = true;
        }

        if(_mailbox.restored){
            dispatchEvent(new P2PEvent(P2PEvent.STATE_RESTORED,{state:_mailbox.state}));
            return;
        }

       if(_neighborHasConnected) _group.addWantObjects(index,index);
       else setTimeout(restoreState,100);
    }



    private function dispose():void{

        connection.removeEventListener(NetStatusEvent.NET_STATUS, connectionStatus);
        _group.removeEventListener(NetStatusEvent.NET_STATUS, connectionStatus);

        listeners.dispose();
        _mailbox && _mailbox.flush();

        _disposed = true;
    }

    /**
     *
     * @param e
     */

    protected function connectionStatus(e:NetStatusEvent):void{

        debug('P2P net status: '+ e.info.code);

        switch(e.info.code){
            // group events
            case NetGroupStatusCodes.POST_MESSAGE:{
                var packet:P2PPacket = e.info.message as P2PPacket;
                handlePacket(packet);
                break;
            }
            case NetGroupStatusCodes.MESSAGE_SENT_TO:{
                var packet:P2PPacket = e.info.message as P2PPacket;
                if(e.info.fromLocal == true){
                    handlePacket(packet);
                }else{
                    _group.sendToNearest(packet,_group.convertPeerIDToGroupAddress(packet.recipientId));
                }
                break;
            }
            case NetGroupStatusCodes.NEIGHBOR_CONNECT:{
                _neighborHasConnected = true;
                dispatchEvent(new P2PEvent(P2PEvent.PEER_CONNECTED,e.info));
                _mailbox && _mailbox.restored && _group.addHaveObjects(0,_mailbox.size);
                break;
            }
            case NetGroupStatusCodes.NEIGHBOR_DISCONNECT:{
                dispatchEvent(new P2PEvent(P2PEvent.PEER_DISCONNECTED,e.info));
                break;
            }
            case NetGroupStatusCodes.REPLICATION_REQUEST:{
                if(e.info.index <= _mailbox.size) _group.writeRequestedObject(e.info.requestID, _mailbox.getMessage(e.info.index));
                else _group.denyRequestedObject(e.info.requestID);
                break;
            }
            case NetGroupStatusCodes.REPLICATION_DATA:{
                _restoreTries = 0;
                _mailbox.restore(e.info.index, e.info.object);
                restoreState(e.info.index+1);
                break;
            }
            case NetGroupStatusCodes.REPLICATION_FAILED:{
                if(_restoreTries === RESTORE_MAX_TRIES){
                    _group.removeWantObjects(e.info.index, e.info.index);
                    dispatchEvent(new P2PEvent(P2PEvent.STATE_RESTORE_FAILED));
                }else{
                    restoreState(e.info.index);
                    _restoreTries++;
                }
                break;
            }
            case NetGroupStatusCodes.REPLICATION_SEND:{
                debug("Index: "+ e.info.index);
                break;
            }
            case NetGroupStatusCodes.CONNECTED:{
                _connected = true;
                if(_replicateState) setTimeout(restoreState,100);
                dispatchEvent(new P2PEvent(P2PEvent.CONNECTED, {group:_group}));
                break;
            }
            case NetGroupStatusCodes.REJECTED:
            case NetGroupStatusCodes.FAILED:{
                if(_connected)
                    dispatchEvent(new P2PEvent(P2PEvent.FAILED,{message: e.info.code}));

                dispose();
                break;
            }

            //net connection events
            case NetConnectionStatusCodes.SUCCESS:
                setupGroup();
                break;
            case NetConnectionStatusCodes.FAILED:
            case NetConnectionStatusCodes.CLOSED:{
                if(_connected)
                    dispatchEvent(new P2PEvent(P2PEvent.FAILED,{message: e.info.code}));
                else if(!_disposed)
                    dispatchEvent(new P2PEvent(P2PEvent.CLOSED));

                dispose();
                break;
            }

        }

    }

    /**
     * Returns NetGroup info or <code>null</code> if is not connected.
     *
     */

    public function get info():NetGroupInfo{

        return _connected ? _group.info : null;

    }

    /**
     *
     */

    public function get connected():Boolean{

        return _connected;

    }


    /**
     *
     * Define whether to receive incoming messages.
     *
     * While using mailbox all incoming messages are stored and dispatched on setting this to TRUE.
     *
     */

    public function get receive():Boolean {
        return _receive;
    }

    public function set receive(value:Boolean):void {
        _receive = value;

        if(value && _mailbox){

            var p:P2PPacket;
            while(p = _mailbox.next()) sendPacket(p);

        }

    }

    /**
     * Return my own peerID
     */

    public function get peerID():String{
        return _connected ? connection.nearID : "";
    }

}
}
