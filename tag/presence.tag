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
    </ul>
    <div class="row">
        <div class="col s12 l6">
            <div class="card">
                <div class="card-content">
                    <div class="card-title">
                        {event.starts.split(' ')[0]}
                        <virtual if={registered}>
                            <a class="right btn red darken-2" onclick={unregister}>Odhlásit</a>
                        </virtual>
                        <virtual if={!registered}>
                            <a class="right btn {disabled: presence.length >= event.capacity || event.locked}"
                                    onclick={register}>Přihlásit</a>
                        </virtual>
                    </div>
                    <blockquote if={!registered && presence.length >= event.capacity}>
                        Termín je již plně obsazen, nelze se přihlásit.
                    </blockquote>
                    <blockquote if={!registered && event.locked}>
                        Nelze se přihlašovat méně než 24 hodin předem.
                    </blockquote>
                    <table class="table striped">
                        <tbody>
                            <tr each={item, i in presence} class={red-text: item.userid == user.id}>
                                <td>{i+1}</td>
                                <td>{item.guestname || item.username} <span if={item.guestname}>(host)</span></td>
                                <td class="text-right">{item.datetime}</td>
                            </tr>
                        </tbody>
                    </table>
                    <div class="col s12 text-right grey-text">
                        Obsazenost:
                        <span class="lighten-2 {red-text: presence.length >= event.capacity}">
                        {presence.length} / {event.capacity}</span>
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
                                    if={show_textarea}
                                    class="materialize-textarea">
                            </textarea>
                            <label if={show_textarea}>Přidat komentář</label>
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
                    <div class="row">
                        <div class="col s6 l3 input-field">
                            <input type="text" ref="guest" onchange={add_guest} />
                            <label>Přidat hosta</label>
                        </div>
                        <div class="col s6 l3">
                            <a class="btn btn-primary">Přidat</a>
                        </div>
                    </div>
                    <div class="row">
                        <div class="col s6 l3 input-field">
                            <input type="number" value={event.capacity} ref="capacity"
                                    min="1" max="30" />
                            <label>Kapacita</label>
                        </div>
                        <div class="col s6 l3">
                            <a class="btn btn-primary" onclick={change_capacity}>Změnit</a>
                        </div>
                    </div>
                </div>
            </div>
        </div>
    </div>

    <style>
        .text-right {
            text-align: right;
        }
        .text-center {
            text-align: center;
        }
    </style>

    <script>
        this.events = []
        this.comments = []
        this.presence = []
        this.event_pos = 0
        this.registered = false
        this.user = {}
        this.show_textarea = false

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
            if (!this.show_textarea) {
                this.show_textarea = true
                return false
            }
            let comment = this.refs.new_comment.value.trim()
            if (!comment.length) {
                this.show_textarea = true
                return false
            }
            $.ajax({
                url: cgi + '/add_comment?eventid=' + this.event.id + '&comment=' + comment,
                success: (d) => {
                    this.get_comments()
                    this.show_textarea = false
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
                    console.log(d)
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
        })
    </script>
</presence>
