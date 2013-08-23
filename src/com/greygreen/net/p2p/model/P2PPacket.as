/**
 * User: palkan
 * Date: 8/20/13
 * Time: 2:25 PM
 */

package com.greygreen.net.p2p.model {
import ru.teachbase.utils.system.registerClazzAlias;


/**
 * Packaging model for data messages.
 *
 */

registerClazzAlias(P2PPacket);



public class P2PPacket extends Object{


    protected var _type:String;

    protected var _system:Boolean;

    protected var _data:*;

    protected var _senderId:String;

    protected var _recipientId:String = "";

    protected var _ts:Number;

    public function P2PPacket(type:String = "default", data:* = null, senderId:String = '', recipientId:String = '', system:Boolean = true) {

        _type = type;
        _data = data;
        _senderId = senderId;
        _recipientId = recipientId;
        _system = system;
        _ts = (new Date()).time;
    }

    /**
     *
     * Sender's <code>NetConnection.nearId</code>.
     *
     */

    public function get senderId():String {
        return _senderId;
    }



    /**
     *
     * Define whether this message must be stored in P2PMailbox.
     *
     * @see P2PMailbox
     */

    public function get system():Boolean {
        return _system;
    }



    /**
     *
     * Message type to differentiate messages.
     *
     */

    public function get type():String {
        return _type;
    }



    /**
     *
     */

    public function get data():* {
        return _data;
    }



    /**
     *
     * Recipient's peerID.
     *
     */

    public function get recipientId():String {
        return _recipientId;
    }


    /**
     *
     * Sender's timestamp in ms.
     *
     */


    public function get ts():Number {
        return _ts;
    }


    /**
     *
     * @param value
     * @private
     */

    public function set senderId(value:String):void {
        _senderId = value;
    }


    /**
     *
     * @param value
     * @private
     */

    public function set system(value:Boolean):void{
        _system = value;
    }


    /**
     *
     * @param value
     * @private
     */

    public function set type (value:String):void{
        _type = value;
    }



    /**
     *
     * @param value
     * @private
     */

    public function set data(value:*):void{
        _data = value;
    }


    /**
     *
     * @param value
     * @private
     */

    public function set recipientId(value:String):void{
        _recipientId = value;
    }



    /**
     *
     * @param value
     * @private
     */

    public function set ts(value:Number):void{
        _ts = ts;
    }


}
}
