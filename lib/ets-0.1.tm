# (c) 2017 Alexander Danilov <alexander.a.danilov@gmail.com> This
# module provide ets command, which implement ETS like storage from
# Erlang into Tcl environment. This module is example for
# tcl-connectedThread.
# Example of ets usage at the end of this file.
# Only few ETS commands implemented now: new, insert, lookup.

package require snit
package require connectedThread

snit::type ets {
    option -name -default "" -readonly 1
    option -type -default "dict" -readonly 1
    option -command -default ""

    component etsCmd

    constructor {args} {
        $self configurelist $args
        set etsCmd [connectedThread ${self}_ets {
            set storage [dict create]
            while 1 {
                lassign [thread::receive] tid data
                set rest [lassign $data action]
                switch -- $action {

                    new {
                        # $ets new tabName
                        set rest [lassign $rest table]
                        dict set storage $table {}
                        thread::send [list ok]
                    }

                    insert {
                        # $ets insert tabName key value
                        set rest [lassign $rest table key value]
                        dict set storage $table $key $value
                        thread::send [list ok]
                    }

                    lookup {
                        # $ets lookup tabName key
                        set rest [lassign $rest table key]
                        if {[dict exists $storage $table]} {
                            thread::send [list ok [dict filter [dict get $storage $table] key $key]]
                        } else {
                            thread::send [list error "$table not found"]
                        }
                    }

                    delete {
                        # $ets delete tabName
                        # or
                        # $ets delete tabName key
                        set rest [lassign $rest table key]
                        if {[dict exists $storage $table]} {
                            set storage [dict unset storage $table $key]
                            puts "storage=$storage"
                            thread::send [list ok]
                        } else {
                            thread::send [list error "$table not found"]
                        }
                    }

                    default {
                        thread::send [list error "invalid action \"$action\" $rest"]
                    }
                }
            }
        }]
        $etsCmd readable [list apply {{command ets} {
            uplevel #0 $command [$ets receive]
        }} $options(-command) $etsCmd]
    }

    method new {tab} {
        $etsCmd send [list new $tab]
    }

    method insert {tab key value} {
        $etsCmd send [list insert $tab $key $value]
    }

    method lookup {tab key} {
        $etsCmd send [list lookup $tab $key]
    }

    method delete {tab key} {
        $etsCmd send [list delete $tab $key]
    }

    delegate method id to etsCmd
}
