<presence>
    <div class="row">
        <div class="col s12">
            <ul class="tabs">
                <li class="tab col {s3: events.length >= 4, s4: events.length < 4}"
                        each={ev, i in events} id="ev{ev.id}">
                    <a onclick={change_event} title="{ev.starts}/{ev.location}"
                            class={active: (location.hash == '#ev' + ev.id) || !location.hash.length, junior: ev.junior}
                            href="#">{ev.title}</a>
                </li>
                <li class="tab col s12" if={!events.length}>
                    <a>Není naplánovaná žádná událost!</a>
                </li>
            </ul>
        </div>
    </div>
    <div class="row" if={events.length}>
        <div class="col s12 l6">
            <div class="card">
                <div class="card-content">
                    <div class="card-title">
                        <span class="evstarts">{event.starts}</span>
                        <virtual if={registered}>
                            <a class="right btn red darken-2" onclick={unregister}>Odhlásit</a>
                        </virtual>
                        <virtual if={!registered && presence.length < event.capacity && !event.locked}>
                            <a class="right btn" onclick={register}>Přihlásit</a>
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
                                <td class={bold: item.userid == user.id, coach: item.coach && event.junior}>
                                    {item.name || item.nickname || item.username}
                                    <span if={item.name}>(host)</span>
                                    <span if={event.junior && item.coach}>(trenér)</span>
                                    <a if={user.admin} onclick={rm_user}
                                            style="cursor: pointer;"
                                            class="red-text">✕</a>
                                </td>
                                <td class="text-right nowrap">{item.datetime}</td>
                            </tr>
                            <tr if={user.admin}>
                                <td>{presence.length + 1}</td>
                                <td><input type="text" placeholder="Lee Chong Wei"
                                        ref="guest" /></td>
                                <td style="text-align: right;">
                                    <a class="btn btn-primary"
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
                                        ref="ccapacity" value={event.capacity} />
                            </div>
                            <span if={!user.admin}>{event.capacity},</span>
                            kurty:
                            <div if={user.admin} style="display: inline;">
                                <input type="number" min="1" max="6"
                                        style="width: auto;" size="1"
                                        onblur={change_courts}
                                        ref="ccourts" value={event.courts} />
                            </div>
                            <span if={!user.admin}>{event.courts}</span>
                            <span if={presence.length && !event.junior}>,
                                cena: ~{Math.ceil((event.courts * 230) / presence.length * 2)} Kč</span>
                        </div>
                    </div>
                </div>
            </div>
        </div>
        <div class="col s12 l6">
            <div class="card">
                <div class="card-content">
                    <div class="card-title" if={comments.length}>
                        Komentáře
                    </div>
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
                                    class="materialize-textarea"
                                    id="new_comment">
                            </textarea>
                            <label for="new_comment">Tvůj komentář</label>
                        </div>
                        <div>
                            <a class="btn" onclick={add_comment}>Komentovat</a>
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
                        <div class="col s6 m2 input-field">
                            <input type="text" ref="date" placeholder="RRRR-MM-DD">
                            <label>Datum</label>
                        </div>
                        <div class="col s6 m2 input-field">
                            <input type="text" ref="time" value="19:00:00">
                            <label>Čas</label>
                        </div>
                        <div class="col s6 m2 input-field">
                            <input type="number" ref="nduration" value="2" />
                            <label>Trvání</label>
                        </div>
                        <div class="col s3 m3 input-field">
                            <input type="number" min="1" ref="ncourts"
                                    value="4" />
                            <label>Kurty</label>
                        </div>
                        <div class="col s3 m3 input-field">
                            <input type="number" min="1" ref="ncapacity"
                                    value="16" />
                            <label>Kapacita</label>
                        </div>
                        <div class="col s3 m3 input-field">
                            <input type="text" value="Zetor" ref="nlocation" />
                            <label>Místo</label>
                        </div>
                        <div class="col s3">
                            <input type="checkbox" id="aevent" ref="aevent" />
                            <label for="aevent">Email</label>
                        </div>
                    </div>
                    <div class="row">
                        <div class="col s12">
                            <div class="row">
                                <div class="col s6 l3">
                                    <input type="checkbox" checked id="uid_all" name="suser" onchange={check_all} />
                                    <label for="uid_all" class="active">Všichni</label>
                                </div>
                                <div class="col s6 l3" each={u in users}>
                                    <input type="checkbox" name="suser"
                                            id={"uid_" + u.id} data-id={u.id} />
                                    <label for={"uid_" + u.id}>{u.nickname || u.username}</label>
                                </div>
                            </ul>
                        </div>
                    </div>
                    <div class="row">
                        <div class="col s12">
                            <a class="btn btn-primary" onclick={create_event}>
                                Vytvořit</a>
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
                font-size: 1.4em;
            }
            .input-field.col label {
                left: 0rem;
            }
        }
        footer {
            text-align: center;
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
        .tab a.junior {
            color: #4095b7;
        }
        .tab a.active.junior {
            background-color: #e0f6ff;
            color: #777;
        }
        .coach {
            color: #D32F2F;
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
            location.hash = '#ev' + ev.item.ev.id
            this.get_comments()
            this.get_presence()
            this.update()
        }

        change_courts(ev) {
            let courts = this.refs.ccourts.value
            $.ajax({
                url: cgi + '/courts?eventid=' + this.event.id
                        + '&courts=' + courts,
                success: (d) => {
                    this.event.courts = courts
                    this.update()
                },
                error: (d) => {
                    console.log(d);
                }
            })
        }

        rm_user(event) {
            $.ajax({
                url: cgi + '/remove_user?id=' + event.item.item.id,
                success: (d) => {
                    this.get_presence()
                },
                error: (d) => {
                    console.log(d);
                }
            })
        }

        change_capacity(ev) {
            let capacity = this.refs.ccapacity.value
            $.ajax({
                url: cgi + '/capacity?eventid=' + this.event.id + '&capacity=' + capacity,
                success: (d) => {
                    this.event.capacity = capacity
                    this.update()
                },
                error: (d) => {
                    console.log(d);
                }
            })
        }

        check_all(ev) {
            $('input[id^="uid_"]').prop('checked', $(ev.target).is(':checked'))
        }

        create_event() {
            let users = ''
            if ($('input#uid_all').not(':checked')) {
                let userarray = []
                $('input[id^="uid_"]:checked').each((i, e) => {
                    userarray.push(e.dataset.id)
                })
                users = userarray.join(',')
            }
            $.ajax({
                url: cgi + '/create_event?title=' + this.refs.eventname.value +
                    '&starts=' + this.refs.date.value + " " + this.refs.time.value +
                    '&duration=' + this.refs.nduration.value +
                    '&users=' + users +
                    '&location=' + this.refs.nlocation.value +
                    '&capacity=' + this.refs.ncapacity.value +
                    '&courts=' + this.refs.ncourts.value +
                    '&announce=' + (this.refs.aevent.checked ? '1' : '0'),
                success: (d) => {
                    this.refs.date.value = ''
                    this.refs.time.value = '19:00:00'
                    this.refs.nlocation.value = 'Zetor'
                    this.refs.ncourts.value = 4
                    this.refs.ncapacity = 16
                    this.refs.eventname.value = ''
                    this.refs.aevent.checked = false
                    $('input[id^="uid_"]').prop('checked', false)
                    this.get_events()
                },
                error: (d) => {
                    console.log('ERROR', d)
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
                    this.presence = []
                    if (this.event.junior) {
                        let coaches = []
                        for (let i=0; i<d.data.length; i++) {
                            if (d.data[i].coach) {
                                coaches.push(d.data[i])
                            }
                            else {
                                this.presence.push(d.data[i])
                            }
                        }
                        for (let i=0; i<coaches.length; i++) {
                            this.presence.push(coaches[i])
                        }
                    }
                    else {
                        this.presence = d.data
                    }
                    this.registered = false
                    for (let i=0; i<this.presence.length; i++) {
                        if (this.presence[i].userid == this.user.id) {
                            this.registered = true
                        }
                    }
                    this.update()
                },
                error: (d) => {
                    console.log(d)
                }
            })
        }

        add_guest() {
            let name = this.refs.guest.value
            $.ajax({
                url: cgi + '/register_guest?eventid=' + this.event.id + '&name=' + name,
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
                url: cgi + '/add_comment?eventid=' + this.event.id +
                        '&comment=' + comment,
                success: (d) => {
                    this.get_comments()
                },
                error: (d) => {
                    console.log(d)
                },
                complete: () => {
                    this.refs.new_comment.value = ""
                    this.update()
                }
            })
            return false
        }

        get_events() {
            $.ajax({
                url: cgi + '/events',
                success: (d) => {
                    this.user = d.user
                    if (!d.data.length) {
                        return
                    }
                    this.events = d.data 
                    let ind = 0
                    if (location.hash) {
                        let h = parseInt(location.hash.substr(3))
                        for (let i=0; i<this.events.length; i++) {
                           if (this.events[i].id == h) {
                             ind = i
                             break
                           }
                        }
                    }
                    this.event = this.events[ind]
                    this.get_presence()
                    this.get_comments()
                    this.update()
                    $('.tabs').tabs();
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
        })
    </script>
</presence>
