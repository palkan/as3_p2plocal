/**
 * User: palkan
 * Date: 8/20/13
 * Time: 2:52 PM
 */
package com.greygreen.net.p2p.model {
import flash.errors.IllegalOperationError;

import ru.teachbase.utils.Strings;


/**
 *
 * P2P connection configuration.
 *
 * Available properties:
 * <li><code>groupName:String = "__default__"</code> - NetGroup name (id)</li>
 * <li><code>ip:String = "225.225.0.1:30303"</code> - IP address for multicast. IP address should begin with 224 or higher and port number greater than 1024.</li>
 * <li><code>saveState:Boolean = false</code>  - define whether to use object replication to store packets.
 *
 * @see P2PPacket$
 *
 */

public class P2PConfig {

    private var _groupName:String="__default__";
    private var _ip:String = "225.225.0.1:30303";
    private var _saveState:Boolean = false;

    /**
     * @throws IllegalOperationError  Incorrect IP address provided.
    **/

    public function P2PConfig(source:Object = null){

        if(!source) return;

        for(var key:String in source){
            this["_"+key] = Strings.serialize(source[key]);
        }

        validateIP();

    }


    protected function validateIP():void{

        const regexp:RegExp = /^\s*\d{3}\.\d{3}\.\d{1}\.\d{1}:(\d{4,})\s*$/;

        var matches:Array;

        if(matches = _ip.match(regexp)){
            if(parseInt(matches[1]) > 1024) return;
        }

        throw new IllegalOperationError("Incorrect IP address provided.");
    }

    /**
     *  Define whether to use object replication to store packets.
     */

    public function get saveState():Boolean {
        return _saveState;
    }

    /**
     *  IP address for multicast.
     */

    public function get ip():String {
        return _ip;
    }

    /**
     *    NetGroup name (id).
     */

    public function get groupName():String {
        return _groupName;
    }
}
}
