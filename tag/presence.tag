<presence>
    <div class="row">
        <div class="col s12">
            <ul class="tabs">
                <li class="tab col s4" each={ev, i in events}>
                    <a onclick={change_event} title="{ev.starts}/{ev.location}"
                            href="#">{ev.title}</a>
                </li>
            </ul>
        </div>
    </div>
    <div class="row">
        <div class="col s12 l6">
            <div class="card">
                <div class="card-content">
                    <div class="card-title">
                        {event.starts}
                        <virtual if={registered}>
                            <a class="right btn red darken-2" onclick={unregister}>Nejdu!</a>
                        </virtual>
                        <virtual if={!registered && (presence.length <= event.capacity && !event.locked)}>
                            <a class="right btn" onclick={register}>Jdu!</a>
                        </virtual>
                    </div>
                    <p if={!registered && presence.length >= event.capacity} class="red-text text-lighten-2">
                        Termín je již plně obsazen, nelze se přihlásit.
                    </p>
                    <p if={!registered && event.locked} class="red-text text-lighten-2">
                        Nelze se přihlašovat méně než 24 hodin předem.
                    </p>
                    <table class="table striped">
                        <tbody>
                            <tr each={item, i in presence}>
                                <td>{i+1}</td>
                                <td class={bold: item.userid == user.id}>
                                    {item.guestname || item.nickname || item.username}
                                    <span if={item.guestname}>(host)</span>
                                </td>
                                <td class="text-right nowrap">{item.datetime}</td>
                            </tr>
                            <tr if={user.admin}>
                                <td>{presence.length + 1}</td>
                                <td><input type="text" ref="guest" /></td>
                                <td style="text-align: right;">
                                    <a class="btn btn-primary"
                                            title="Přidat hosta"
                                            onclick={add_guest}>Přidat</a>
                                </td>
                            </tr>
                        </tbody>
                    </table>
                    <div class="row event-info">
                        <div class="col s12">
                            kapacita:
                            <div if={user.admin} style="display: inline;">
                                <input type="number" min="4" max="100"
                                        style="width: auto;" size="2"
                                        onblur={change_capacity}
                                        ref="capacity" value={event.capacity} />,
                            </div>
                            <div if={!user.admin}>
                                {event.capacity},
                            </div>
                            kurty: {event.courts},
                            <!-- místo: {event.location} -->
                            <span if={presence.length}>, cena: ~{Math.ceil((event.courts * 200) / presence.length * 2)} Kč</span>
                        </div>
                    </div>
                </div>
            </div>
        </div>
        <div class="col s12 l6">
            <div class="card">
                <div class="card-content">
                    <ul class="collection" if={comments.length}>
                        <li each={comment in comments} class="collection-item"
                                title={comment.datetime}>
                            <span class="badge"><i class="fa fa-user"></i> {comment.name}</span>
                            {comment.text}
                        </li>
                    </ul>
                    <form>
                        <div class="input-field">
                            <textarea onchange={changed_area} ref="new_comment"
                                    class="materialize-textarea">
                            </textarea>
                            <label if={show_textarea}>Přidat komentář</label>
                        </div>
                        <div class="input-field">
                            <label>
                                <input type="checkbox" id="inform-admin" />
                                <span>Dát vědět organizátorům</span>
                            </label>
                        </div>
                        <div class="input-field">
                            <a class="btn" onclick={add_comment}>Přidat komentář</a>
                        </div>
                    </form>
                </div>
            </div>
        </div>
    </div>
    <div class="row">
        <div class="col s12">
            <div class="card" if={user.admin}>
                <div class="card-content">
                    <div class="card-title">Přidat událost</div>
                    <div class="row">
                        <div class="col s12 m6 input-field">
                            <input type="text" ref="eventname" />
                            <label>Název akce</label>
                        </div>
                        <div class="col s6 m3 input-field">
                            <input type="text" class="datepicker" ref="date">
                            <label>Datum</label>
                        </div>
                        <div class="col s6 m3 input-field">
                            <input type="text" class="timepicker" ref="time">
                            <label>Čas</label>
                        </div>
                        <div class="col s3 m3 input-field">
                            <input type="number" min="1" ref="courts"
                                    value="4" />
                            <label>Kurty</label>
                        </div>
                        <div class="col s3 m3 input-field">
                            <input type="number" min="1" ref="ncapacity"
                                    value="16" />
                            <label>Kapacita</label>
                        </div>
                        <div class="col s3 input-field">
                            <input type="checkbox" ref="announce-new-event" />
                            <label>Email</label>
                        </div>
                    </div>
                    <div class="row">
                        <div class="col s12 input-field">
                            <ul>
                                <li class="input-field">
                                    <input type="checkbox" checked id="uid_all" name="suser" />
                                    <label for="uid_all" class="active">Všichni</label>
                                </li>
                                <li each={u in users} class="input-field">
                                    <input type="checkbox" name="suser" id={"uid_" + u.id} />
                                    <label for={"uid_" + u.id}>{u.nickname || u.username}</label>
                                </li>
                            </ul>
                        </div>
                    </div>
                    <div class="row">
                        <div class="col s12">
                            <a class="btn btn-primary" onclick={add_event}>
                                Vytvořit událost</a>
                        </div>
                    </div>
                </div>
            </div>
        </div>
    </div>

    <style>
        @media only screen and (max-width: 500px) {
            .tabs .tab a {
                padding: 0 .2em;
            }
            .card .card-content {
                padding: .5em;
            }
            .row .col {
                padding: 0 .2em;
            }
            .row {
                margin-bottom: .2em;
            }
            .card {
                margin-bottom: .2em;
            }
            .card .card-title {
                font-size: 1.5em;
            }
        }
        .tabs .tab a.active {
            background-color: #FFECEC;
        }
        .nowrap {
            white-space: nowrap;
        }
        .text-right {
            text-align: right;
        }
        .text-center {
            text-align: center;
        }
        .bold {
            font-weight: bold;
        }
    </style>

    <script>
        this.events = []
        this.comments = []
        this.presence = []
        this.event_pos = 0
        this.registered = false
        this.user = {}
        this.users = []

        change_event(ev) {
            this.event = ev.item.ev
            this.get_comments()
            this.get_presence()
            this.update()
        }

        change_capacity(ev) {
            let capacity = this.refs.capacity.value
            $.ajax({
                url: cgi + '/capacity?eventid=' + this.event.id + '&capacity=' + capacity,
                success: (d) => {
                    // TODO: only update capacity
                    this.get_events()
                },
                error: (d) => {
                    console.log(d);
                }
            })
        }

        get_users() {
            $.ajax({
                url: cgi + '/users',
                success: (d) => {
                    this.users = d.data
                    this.update()
                },
                error: (d) => {
                    console.log(d)
                }
            })
        }
        this.get_users()

        get_presence() {
            $.ajax({
                url: cgi + '/presence?eventid=' + this.event.id,
                success: (d) => {
                    this.presence = d.data
                    this.registered = false
                    for (let i=0; i<this.presence.length; i++) {
                        if (this.presence[i].userid == this.user.id) {
                            this.registered = true
                        }
                    }
                    this.update()
                },
                error: (d) => {
                    console.log(d);
                }
            })
        }

        add_guest() {
            let guestname = this.refs.guest.value
            $.ajax({
                url: cgi + '/register_guest?eventid=' + this.event.id + '&guestname=' + guestname,
                success: (d) => {
                    this.get_presence()
                    this.refs.guest.value = ""
                    this.update()
                },
                error: (d) => {
                    console.log(d)
                }
            })

        }

        add_comment(ev) {
            let comment = this.refs.new_comment.value.trim()
            if (!comment.length) {
                return false
            }
            $.ajax({
                url: cgi + '/add_comment?eventid=' + this.event.id + '&comment=' + comment,
                success: (d) => {
                    this.refs.new_comment.value = ""
                    this.get_comments()
                    this.update()
                },
                error: (d) => {
                    console.log(d)
                }
            })
            return false
        }

        get_events() {
            $.ajax({
                url: cgi + '/events',
                success: (d) => {
                    this.events = d.data 
                    this.event = this.events[0]
                    this.user = d.user
                    this.get_presence()
                    this.get_comments()
                    this.update()
                    $(document).ready(function(){
                        $('.tabs').tabs();
                    });
                },
                error: (d) => {
                    console.log(d)
                }
            })
        }
        this.get_events()

        get_comments() {
            $.ajax({
                url: cgi + '/comments?eventid=' + this.event.id,
                success: (d) => {
                    this.comments = d.data
                    this.update()
                },
                error: (d) => {
                    console.log(d)
                }
            })
        }

        register() {
            $.ajax({
                url: cgi + '/register?eventid=' + this.event.id,
                success: (d) => {
                    this.get_presence()
                },
                error: (d) => {
                    console.log(d)
                }
            })
        }

        unregister() {
            $.ajax({
                url: cgi + '/unregister?eventid=' + this.event.id,
                success: (d) => {
                    this.get_presence()
                },
                error: (d) => {
                    console.log(d)
                }
            })
        }

        this.on('updated', () => {
            $('input + label').addClass('active');
            $('.timepicker').timepicker({
                defaultTime: '19:00',
                cancel: 'Zrušit',
                clear: 'Reset',
                done: 'OK'
            })
            $('.datepicker').datepicker({
                done: 'OK',
                clear: 'Reset',
                cancel: 'Zrušit'
            })
        })
    </script>
</presence>
