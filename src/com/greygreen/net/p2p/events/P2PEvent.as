/**
 * User: palkan
 * Date: 8/20/13
 * Time: 2:07 PM
 */
package com.greygreen.net.p2p.events {
import flash.events.Event;

public class P2PEvent extends Event{

    /**
     * Indicates that NetConnection and NetGroup connected successfully.
     *
     * <code>info.group</code> contains corresponding NetGroup object.
     *
     * @eventType p2p:connected
     */

    public static const CONNECTED:String = "p2p:connected";


    /**
     * Indicates that replicated session stated has been restored and client starting to dispatch new messages.
     *
     * Dispatches only if <code>P2PConfig.saveState == true</code>.
     *
     * <code>info.state:Array</code> contains history messages.
     *
     * @eventType p2p:state_restored
     */

    public static const STATE_RESTORED:String = "p2p:state_restored";

    /**
     * Indicates that error occured during state restore (maybe due to denial overhead).
     *
     * Dispatches only if <code>P2PConfig.saveState == true</code>.
     *
     * <code>info</code> is null
     *
     * @eventType p2p:state_restore_failed
     */

    public static const STATE_RESTORE_FAILED:String = "p2p:state_restore_failed";

    /**
     *
     * NetConnection or NetGroup failed to connect.
     *
     * <code>info.message</code> contains String representation of error.
     *
     * @eventType p2p:failed
     *
     */

    public static const FAILED:String = "p2p:failed";


    /**
     *
     * NetConnection was closed successfully.
     *
     * <code>info</code> is null.
     *
     * @eventType p2p:closed
     *
     */

    public static const CLOSED:String = "p2p:closed";

    /**
     * New peer connected as a neighbor.
     *
     * <code>info.peerID</code> contains the peer's <code>peerID</code>.
     *
     * @eventType p2p:peer_connected
     */

    public static const PEER_CONNECTED:String = "p2p:peer_connected";

    /**
     * Peer disconnected.
     *
     * <code>info.peerID</code> contains the peer's <code>peerID</code>.
     *
     * @eventType p2p:peer_disconnected
     */

    public static const PEER_DISCONNECTED:String = "p2p:peer_disconnected";


    private var _info:Object;

    public function P2PEvent(type:String, info:Object = null, bubbles:Boolean = false, cancelable:Boolean = false) {

        super(type,bubbles,cancelable);

        _info = info;

    }

    /**
     * @inheritDoc
     */

    override public function clone():Event{
        return new P2PEvent(type,info,bubbles,cancelable);
    }

    /**
     * Additional info. Depends on <code>type</code>.
     */

    public function get info():Object {
        return _info;
    }
}
}
