/**
 * User: palkan
 * Date: 8/20/13
 * Time: 2:00 PM
 */
package com.greygreen.net.p2p {
import com.greygreen.net.p2p.model.P2PPacket;

import flash.net.NetGroup;

public class P2PMailbox {

    private const storage:Array = [];

    private const temp:Array = [];

    private var _restoreWaiting:Boolean = false;

    private var _restored:Boolean = false;

    private var _expectedSize:Number = 0;

    private var _next:Number = 0;

    private var _group:NetGroup;

    public function P2PMailbox(group:NetGroup) {
        _group = group;
    }

    /**
     *
     * Add new message.
     *
     * @param packet
     * @param incrNext define whether to increment next message to dispatch counter. Prevents messaging loopback.
     */


    public function push(packet:P2PPacket, incrNext:Boolean = false):void{

       storage.push(packet);

       _restored && _group.addHaveObjects(storage.length,storage.length);

       incrNext && _next++;
    }

    /**
     *
     * Return next element to dispatch.
     *
     * @return
     */


    public function next():P2PPacket{

       if(!_restored || _next > storage.length - 1) return null;

       return storage[_next++];
    }

    /**
     *
     * Add message from history.
     *
     * If <code>index == 0</code> than <code>data</code> is expected history size.
     *
     * Updates <code>restore</code> value.
     *
     * @param index
     * @param data
     */


    public function restore(index:Number, data:*):void{

        if(index == 0){
            _expectedSize = Number(data);
            _restored = (_expectedSize == 0);
            _restoreWaiting = !_restored;
            return;
        }

        temp.push(data as P2PPacket);

        !_restored && (restored = (_expectedSize == temp.length));
    }


    /**
     *
     * Return message with index <code>index-1</code> from mailbox or size of mailbox if <code>index == 0</code>.
     *
     * @param index
     * @return
     */


    public function getMessage(index:Number):Object{
        return index ? storage[index-1] : storage.length;
    }


    /**
     *
     * Flush all messages.
     *
     */


    public function flush():void{

        storage.length = 0;
        temp.length = 0;

    }

    /**
     * Return state as array of packets
     *
     */

    public function get state():Array{
        return temp;
    }


    /**
     *
     */

    public function get size():Number{
        return storage.length;
    }

    /**
     *
     * Define whether mailbox is in restoring state (i.e. collecting state data).
     *
     * If TRUE than all new messages are pushed to <code>temp</code> storage and have to fetched later.
     *
     */

    public function get restored():Boolean {
        return _restored;
    }

    public function set restored(value:Boolean):void{
        if(_restored == value) return;

        _restored = value;

        if(!value) return;

        _restoreWaiting && (_restoreWaiting = false);

        for each(var p:P2PPacket in temp) storage.unshift(p);

        _next = temp.length;

    }


    /**
     *
     * Indicates that we asked peers for data but haven't received anything yet (we don't know the size of a state array).
     *
     */


    public function get restoreWaiting():Boolean {
        return _restoreWaiting;
    }
}
}
