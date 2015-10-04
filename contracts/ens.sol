import 'controller.sol';
import 'request.sol';
import 'dapple/core/debug.sol';


contract ENS is ENSInterface
              , ENSGetRequestManager
              , Debug
{
    mapping( uint => node ) nodes;
    uint next_id;

    function get_controller( uint node_id ) constant returns (ENSNodeControllerInterface) {
        return nodes[node_id].controller;
    }

    function ENS( ENSNodeControllerInterface root_controller ) {
        new_node( root_controller );
    }

    function new_node( ENSNodeControllerInterface controller ) returns (uint) {
        node memory N;
        N.controller = controller;
        var id = next_id;
        nodes[id] = N;
        next_id++;
        return id;
    }
    function set( uint node_id, bytes key, bytes32 value ) returns (bool) {
        //logs("in app set");
        var node = nodes[node_id];
        if( node.frozen_entries[key].is_frozen ) {
            return false;
        } else {
            return node.controller.ens_set( msg.sender, key, value );
        }
    }
    function is_frozen( entry e ) internal returns (bool) {
        return e.is_frozen;// replace with byte accessor
    }
    function get( uint node_id, bytes key)
//             requires_depth( 2 )
             returns (bytes32 value, bool success)
    {
        var node = nodes[node_id];
        var e = node.frozen_entries[key];
        if( is_frozen(e) ) {
            value = e.value;
            success = true;
        } else {
            uint request_id = start_request();
            node.controller.ens_get_request(key);
            success = close_request( request_id );
            if( success ) { 
                value = request_result( request_id );
            } else {
                value = bytes32(0x0);
            }
        }
    }
    function get_callback( bytes32 value )
    {
        resolve_request( value );
    }
    function freeze( uint node_id, bytes key ) returns (bool) {
        var node = nodes[node_id];
        if( node.frozen_entries[key].is_frozen ) {
            return true; // it is actually frozen even though this call "failed"
        }
        if( node.controller.ens_can_freeze( msg.sender, key ) ) {
            node.frozen_entries[key].value = get( node_id, key );
            node.frozen_entries[key].is_frozen = true;
            return true;
        }
        return false;
    }

/*
    function set( string path, bytes32 value ) returns (bool) {
    }
    function get( string path ) returns (bytes32 value, byte flags) {
    }
    function freeze( string path ) returns (bool) {
    }
*/
}
