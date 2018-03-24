<presence>
    <h4>Hráč: {user.name}</h4>
    <div class="row">
        <div class="col s12">
            <ul class="tabs">
                <li class="tab col s4" each={ev, i in events}>
                    <a onclick={change_event}
                            href="#event{i+1}">{ev.title}</a>
                    {ev.starts}
                </li>
            </ul>
        </div>
    </ul>
    <div class="row">
        <div class="col s12">
            <table>
                <tr>
                    <th>Kdy</th>
                    <td>{event.starts}</td>
                </tr>
                <tr>
                    <th>Kde</th>
                    <td>{event.location}</td>
                </tr>
                <tr>
                    <th>Kurtů</th>
                    <td>{event.courts}</td>
                </tr>
            </table>
        </div>
    </div>
    <div class="row">
        <div class="col s12 text-center">
            <virtual if={registered}>
                <button class="btn red darken-2" onclick={unregister}>Odhlásit</button>
            </virtual>
            <virtual if={!registered}>
                <button class="btn red darken-2" onclick={register}>Přihlásit</button>
            </virtual>
        </div>
    </div>
    <div class="row">
        <div class="col s12 l6">
            <div class="card">
                <div class="card-content">
                    <div class="card-title">Přihlášení {presence.length} / {event.capacity}</div>
                    <table class="table striped">
                        <tbody>
                            <tr each={item, i in presence} class={red-text: item.userid == user.id}>
                                <td>{i+1}</td>
                                <td>{item.username}</td>
                                <td class="time">{item.datetime}</td>
                            </tr>
                        </tbody>
                    </table>
                </div>
            </div>
        </div>
        <div class="col s12 l6">
            <div class="card">
                <div class="card-content">
                    <ul class="comments" if={comments.length}>
                        <li each={comment in comments} class={red-text: comment.userid == user.id}>
                            <p>{comment.text}</p>
                            <span>{comment.userid}</span>
                            <span class="datetime">({comment.datetime})</span>
                        </li>
                    </ul>
                    <form>
                        <div class="input-field">
                            <textarea onchange={changed_area}
                                    class="materialize-textarea">
                            </textarea>
                            <label>Přidat komentář</label>
                        </div>
                        <div class="input-field">
                            <input type="submit" class="btn"
                                    value="Přidat komentář" />
                        </div>
                    </form>
                </div>
            </div>
        </div>
    </div>
    <div class="card" if={user.admin}>
        <div class="card-content" >
            <h4 class="card-title">Admin</h4>
            <div class="row">
                <div class="col s6 input-field">
                    <input type="text" onchange={add_guest} />
                    <label>Přidat hosta</label>
                </div>
                <div class="col s4 input-field">
                    <input type="checkbox" />
                    <label>Oznámit emailem?</label>
                </div>
                <div class="col s2">
                    <a class="btn btn-primary">Přidat</a>
                </div>
            </div>
            <div class="row">
                <div class="col s2 input-field">
                    <input type="number" onchange={change_capacity}
                            value={event.capacity} />
                </div>
                <div class="col s4 input-field">
                    <input type="checkbox" />
                    <label>Oznámit emailem?</label>
                </div>
                <div class="col offset-s4 s2">
                    <a class="btn btn-primary">Změnit</a>
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

        change_event(ev) {
            this.event = ev.item.ev
            this.get_comments(this.event.id)
            this.get_presence(this.event.id)
            this.update()
        }

        get_presence(eventid) {
            $.ajax({
                url: cgi + '/presence?eventid=' + eventid,
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

        events() {
            $.ajax({
                url: cgi + '/events',
                success: (d) => {
                    console.log(d)
                    this.events = d.data 
                    this.event = this.events[0]
                    this.eventid = this.event.id
                    this.user = d.user
                    this.get_presence(this.eventid)
                    this.get_comments(this.eventid)
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
        this.events()

        get_comments(eventid) {
            $.ajax({
                url: cgi + '/comments?eventid=' + eventid,
                success: (d) => {
                    console.log(d)
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
                    this.get_presence(this.event.id)
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
                    this.get_presence(this.event.id)
                },
                error: (d) => {
                    console.log(d)
                }
            })
        }

        this.on('updated', () => {
            // TODO: localize all datetime strings
        })
    </script>
</presence>
