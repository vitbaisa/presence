<presence>
    <div class="row">
        <div class="col s12">
            <ul class="tabs">
                <li class="tab col {s3: events.length == 4, s4: events.length == 3, s2: events.length > 4 && events.length <=6, s1: events.length > 6}"
                        each={ev, i in events} id="ev{ev.id}">
                    <a onclick={change_event} title="{ev.starts}/{ev.location}"
                            class={active: (location.hash == '#ev' + ev.id) || !location.hash.length, junior: ev.junior}
                            href="#">{ev.title}</a>
                </li>
                <li class="tab col s12" if={!events.length}>
                    <a>Žádná dostupná událost</a>
                </li>
            </ul>
        </div>
    </div>
    <div class="row" if={events.length}>
        <div class="col s12 l6">
            <div class="card">
                <div class="card-content">
                    <div class="card-title">
                        <span>{event.title}
                            <span class="date">{event.date}</span>
                            <span class="time">od {event.time}</span>
                        </span>
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
                        Nelze se přihlašovat méně než {event.in_advance} hodin předem.
                    </p>
                    <table class="table striped">
                        <tbody>
                            <tr each={item, i in presence}>
                                <td>{i+1}</td>
                                <td class={bold: item.userid == user.username, coach: item.coach && event.junior}>
                                    {item.name || item.fullname || item.username}
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
                    <button class="btn" onclick={showUsers}
                            if={user.admin && !show_users}>Zobrazit seznam lidí</button>
                    <div class="row" if={user.admin && show_users}>
                        <h5>Kdo vidí a může se přihlásit na tento termín</h5>
                        <div class="col s6" each={u in users}>
                            <input type="checkbox" id="att_{u.username}"
                                    checked={event.restriction.indexOf(u.username) >= 0}
                                    onchange={changeRestriction} />
                            <label for="att_{u.username}">{u.fullname || u.username}</label>
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
                        <li each={comment in comments} class="collection-item">
                            <span class="badge"><small>{comment.name},
                                {comment.datetime.replace(/[0-9]*-([0-9]*)-([0-9]*) ([0-9]*):([0-9]*):[0-9]*/, "$2. $1. $3:$4")}</small></span>
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
            <button if={user.admin && !showNewEvent} class="btn"
                    onclick={toggleNewEvent}>Vytvořit novou událost</button>
            <div class="card" if={user.admin && showNewEvent}>
                <div class="card-content">
                    <span class="card-title">Nová událost</span>
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
                        <div class="col s3 m2 input-field">
                            <input type="number" min="1" ref="ncourts"
                                    value="4" />
                            <label>Kurty</label>
                        </div>
                        <div class="col s3 m2 input-field">
                            <input type="number" min="1" ref="ncapacity"
                                    value="16" />
                            <label>Kapacita</label>
                        </div>
                        <div class="col s3 m2 input-field">
                            <input type="text" value="Zetor" ref="nlocation" />
                            <label>Místo</label>
                        </div>
                        <div class="col s3 m2">
                            <input type="checkbox" id="pinned" />
                            <label for="pinned" class="active">Připnout</label>
                        </div>
                    </div>
                    <div class="row">
                        <div class="col s12">
                            <div class="row">
                                <div class="col s6 l3">
                                    <input type="checkbox" checked id="uid_all"
                                            name="suser" onchange={check_all} />
                                    <label for="uid_all" class="active">Všichni</label>
                                </div>
                                <div class="col s6 l3" each={u in users}>
                                    <input type="checkbox" name="suser"
                                            id={"uid_" + u.username} data-id={u.username} />
                                    <label for={"uid_" + u.username}>{u.fullname || u.username}</label>
                                </div>
                            </div>
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
    <div class="row" if={user.admin}>
        <div class="col s12">
            <button class="btn" onclick={onShowRepeated}
                    if={!showRepeatedEvents}>Zobrazit opakující se akce</button>
            <div class="card" if={showRepeatedEvents}>
                <div class="card-content">
                    <div class="card-title">Opakující se události</div>
                    <p>POZOR: Změny v této tabulce se projeví nejdřív za týden.
                        Juniorské tréninky musí mít v názvu "JUNIOŘI"!</p>
                    <div class="row" each={item, idx in cronevents}>
                        <div class="col s3 m1">
                            <select name="day" class="browser-default" onchange={changeCE}>
                                <option each={day, dayidx in days} value={dayidx} selected={item.day == dayidx}>{day}</option>
                            </select>
                        </div>
                        <div class="col s9 m3">
                            <input name="title" value={item.title} onchange={changeCE} />
                        </div>
                        <div class="col s6 m3">
                            <input name="location" value={item.location} onchange={changeCE} />
                        </div>
                        <div class="col s6 m2">
                            <input name="starts" value={item.starts} onchange={changeCE} />
                        </div>
                        <div class="col s4 m1">
                            <input name="duration" type="number" min="1" max="12" value={item.duration} onchange={changeCE} />
                        </div>
                        <div class="col s4 m1">
                            <input name="capacity" type="number" min="1" max="50" value={item.capacity} onchange={changeCE} />
                        </div>
                        <div class="col s4 m1">
                            <input name="courts" type="number" min="1" max="6" value={item.courts} onchange={changeCE} /></td>
                        </div>
                        <div class="col s6 m3" each={u in users}>
                            <input type="checkbox" id="ce_{idx}_{u.username}"
                                    checked={item.restriction.indexOf(u.username) >= 0}
                                    onchange={changeCronEventRestriction.bind(this, idx)} />
                            <label for="ce_{idx}_{u.username}">{u.fullname || u.username}</label>
                        </div>
                    </div>
                </div>
            </div>
        </div>
    </div>
    <div class="row">
        <div class="col s12">
            <button if={!showNewUser && user.admin}
                    onclick={onShowNewUser} class="btn">Přidat hráče</button>
            <div class="card" if={user.admin && showNewUser}>
                <div class="card-content">
                    <div class="card-title">Nový hráč</div>
                    <p>Uživatelské jméno smí obsahovat pouze malá písmena, žádnou mezeru.</p>
                    <div class="row">
                        <div class="col s12 m6 l3">
                            <input ref="username" placeholder="Uživatelské jméno" />
                        </div>
                        <div class="col s12 m6 l3">
                            <input ref="fullname" placeholder="Plné jméno" />
                        </div>
                        <div class="col s12 m6 l3">
                            <input ref="password" type="password" />
                        </div>
                        <div class="col s12 m6 l3">
                            <button onclick={add_user} class="btn">Přidat hráče</button>
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
            .row {
                width: 100%;
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
        span.time, span.date {
            font-size: 45%;
            font-family: Arial, sans-serif;
            border-radius: 4px;
            padding: 2px 3px;
            background-color: #26A69A;
            color: white;
            font-weight: bold;
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
        this.usersMap = {}
        this.showNewEvent = false
        this.show_users = false
        this.cronevents = []
        this.days = ["Pondělí", "Úterý", "Středa", "Čtvrtek", "Pátek", "Sobota", "Neděle", "Nikdy"]
        this.showRepeatedEvents = false
        this.showNewUser = false

        onShowRepeated() {
            this.showRepeatedEvents = !this.showRepeatedEvents
        }

        onShowNewUser() {
            this.showNewUser = true
        }

        add_user() {
            let xhr = new XMLHttpRequest()
            xhr.withCredentials = true
            xhr.onload = function () {
                if (xhr.status === 200) {
                    this.showNewUser = false
                    this.get_users()
                }
            }.bind(this)
            xhr.open('POST', "/user")
            xhr.send(JSON.stringify({
                username: encodeURIComponent(this.refs.username.value),
                fullname: encodeURIComponent(this.refs.fullname.value),
                password: encodeURIComponent(this.refs.password.value)
            }))
        }

        changeCE(e) {
            this.cronevents[e.item.idx][e.target.name] = e.target.value
            if (e.target.name == "day") {
                this.cronevents[e.item.idx][e.target.name] = parseInt(e.target.value)
            }
            this.set_cronevents()
        }

        get_cronevents() {
            let xhr = new XMLHttpRequest()
            xhr.withCredentials = true
            xhr.onload = function () {
                if (xhr.status === 200) {
                    let payload = JSON.parse(xhr.responseText)
                    this.cronevents = payload.data.events
                    this.update()
                }
                else {
                    console.log(xhr.responseText)
                }
            }.bind(this)
            xhr.open("GET", "/cronevents")
            xhr.send()
        }

        set_cronevents() {
            for (let i=0; i<this.cronevents.length; i++) {
                this.cronevents[i].restriction = this.cronevents[i].restriction.join(',')
            }
            let xhr = new XMLHttpRequest()
            xhr.withCredentials = true
            xhr.onload = function () {
                if (xhr.status === 200) {
                    this.get_cronevents()
                    this.update()
                }
                else {
                    console.log(xhr.responseText)
                }
            }.bind(this)
            xhr.open("POST", "/cronevents")
            xhr.send(JSON.stringify({data: {events: this.cronevents}}))
        }

        showUsers() {
            this.show_users = true
        }

        toggleNewEvent() {
            this.showNewEvent = true
            window.scrollTo(0, document.body.scrollHeight)
        }

        changeCronEventRestriction(idx, ev) {
            let uid = ev.item.u.username
            if (ev.currentTarget.checked) {
                if (this.cronevents[idx].restriction.indexOf(uid) == -1) {
                    this.cronevents[idx].restriction.push(uid)
                    this.cronevents[idx].restriction.sort()
                }
            }
            else {
                let ind = this.cronevents[idx].restriction.indexOf(uid)
                if (ind != -1) {
                    this.cronevents[idx].restriction.splice(ind, 1)
                }
            }
            this.set_cronevents()
        }

        changeRestriction(ev) {
            let uid = ev.item.u.username
            if (ev.currentTarget.checked) {
                if (this.event.restriction.indexOf(uid) == -1) {
                    this.event.restriction.push(uid)
                    this.event.restriction.sort()
                }
            }
            else {
                let ind = this.event.restriction.indexOf(uid)
                if (ind != -1) {
                    this.event.restriction.splice(ind, 1)
                }
            }
            let restr = this.event.restriction.join(",")
            let xhr = new XMLHttpRequest()
            xhr.withCredentials = true
            xhr.onload = function () {}
            xhr.open('POST', "/restriction")
            xhr.send(JSON.stringify({
                eventid: this.event.id,
                restriction: restr
            }))
        }

        change_event(ev) {
            this.event = ev.item.ev
            location.hash = '#ev' + ev.item.ev.id
            this.get_comments()
            this.get_presence()
            this.update()
        }

        change_courts(ev) {
            let courts = this.refs.ccourts.value
            let xhr = new XMLHttpRequest()
            xhr.withCredentials = true
            xhr.onload = function () {
                this.event.courts = courts
                this.update()
            }.bind(this)
            xhr.open('GET', "/courts")
            xhr.send(JSON.stringify({
                eventid: this.event.id,
                courts: courts
            }))
        }

        rm_user(event) {
            let xhr = new XMLHttpRequest()
            xhr.withCredentials = true
            xhr.onload = function () {
                this.get_presence()
            }.bind(this)
            xhr.open('DELETE', "/user")
            xhr.send(JSON.stringify({
                id: event.item.item.username
            }))
        }

        change_capacity(ev) {
            let capacity = this.refs.ccapacity.value
            let xhr = new XMLHttpRequest()
            xhr.withCredentials = true
            xhr.onload = function () {
                this.event.capacity = capacity
                this.update()
            }.bind(this)
            xhr.open('GET', "/capacity")
            xhr.send(JSON.stringify({
                eventid: this.event.id,
                capacity: capacity
            }))
        }

        pinEvent(event) {
            if ((event.target).is(':checked')) {
                // TODO
            }
        }

        check_all(ev) {
            document.querySelectorAll('input[id^="uid_"]').forEach(function (i) {
                i.checked = true
            })
            // test
        }

        remove_event() {
            let xhr = new XMLHttpRequest()
            xhr.withCredentials = true
            xhr.onload = function () {
                this.get_events()
            }.bind(this)
            xhr.open('DELETE', "/event")
            xhr.send(JSON.stringify({
                eventid: this.event.id
            }))
        }

        create_event() {
            // TODO: add event creator to restriction list
            let users = ''
            if (document.querySelectorAll('input#uid_all:not(:checked)').length) {
                let userarray = []
                document.querySelectorAll('input[id^="uid_"]:checked').forEach(function (e) {
                    userarray.push(e.dataset.id)
                })
                users = userarray.join(',')
            }
            let pinned = document.getElementById("pinned").checked
            let xhr = new XMLHttpRequest()
            xhr.withCredentials = true
            xhr.onload = function () {
                this.refs.date.value = ''
                this.refs.time.value = '19:00:00'
                this.refs.nlocation.value = 'Zetor'
                this.refs.ncourts.value = 4
                this.refs.ncapacity = 16
                this.refs.eventname.value = ''
                document.querySelectorAll('input[id^="uid_"]').forEach(function (i) { i.checked = false })
                this.get_events()
            }.bind(this)
            xhr.open('POST', "/event")
            xhr.send(JSON.stringify({
                title: this.refs.eventname.value,
                starts: this.refs.date.value + " " + this.refs.time.value,
                duration: this.refs.nduration.value,
                users: users,
                location: this.refs.nlocation.value,
                capacity: this.refs.ncapacity.value,
                courts: this.refs.ncourts.value,
                pinned: pinner ? 1 : 0
            }))
        }

        get_users() {
            let xhr = new XMLHttpRequest()
            xhr.withCredentials = true
            xhr.onload = function () {
                let payload = JSON.parse(xhr.responseText)
                this.users = payload.data
                for (let i=0; i<this.users.length; i++) {
                    this.usersMap[this.users[i].username] = this.users[i].fullname || this.users[i].username
                }
                this.update()
            }.bind(this)
            xhr.open('GET', "/users")
            xhr.send()
        }
        this.get_users()

        get_presence() {
            let xhr = new XMLHttpRequest()
            xhr.withCredentials = true
            xhr.onload = function () {
                let d = JSON.parse(xhr.responseText)
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
                    if (this.presence[i].userid == this.user.username) {
                        this.registered = true
                    }
                }
                this.update()
            }.bind(this)
            xhr.open('GET', "/presence?eventid=" + this.event.id)
            xhr.send()
        }

        add_guest() {
            let name = this.refs.guest.value
            let xhr = new XMLHttpRequest()
            xhr.withCredentials = true
            xhr.onload = function () {
                this.get_presence()
                this.refs.guest.value = ""
                this.update()
            }.bind(this)
            xhr.open('POST', "/register")
            xhr.send(JSON.stringify({
                guest: true,
                eventid: this.event.id,
                name: name
            }))
        }

        add_comment() {
            let comment = this.refs.new_comment.value.trim()
            if (!comment.length) {
                return false
            }
            let xhr = new XMLHttpRequest()
            xhr.withCredentials = true
            xhr.onload = function () {
                this.refs.new_comment.value = ""
                this.get_comments()
            }.bind(this)
            xhr.open('POST', "/comment")
            xhr.send(JSON.stringify({
                eventid: this.event.id,
                comment: encodeURIComponent(comment)
            }))
            return false
        }

        get_events() {
            let xhr = new XMLHttpRequest()
            xhr.withCredentials = true
            xhr.onload = function () {
                let d = JSON.parse(xhr.responseText)
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
                this.user.admin && this.get_cronevents()
                this.update()
                document.querySelector('.tabs').tabs()
            }.bind(this)
            xhr.open('GET', "/events")
            xhr.send()
        }
        this.get_events()

        get_comments() {
            let xhr = new XMLHttpRequest()
            xhr.withCredentials = true
            xhr.onload = function () {
                let payload = JSON.parse(xhr.responseText)
                this.comments = payload.data
                this.update()
            }.bind(this)
            xhr.open('GET', "/comments?eventid=" + this.event.id)
            xhr.send()
        }

        register() {
            let xhr = new XMLHttpRequest()
            xhr.withCredentials = true
            xhr.onload = function () {
                this.get_presence()
            }.bind(this)
            xhr.open('POST', "/register")
            xhr.send(JSON.stringify({
                eventid: this.event.id
            }))
        }

        unregister() {
            let xhr = new XMLHttpRequest()
            xhr.withCredentials = true
            xhr.onload = function () {
                this.get_presence() // really necessary?
            }.bind(this)
            xhr.open('DELETE', "/register")
            xhr.send(JSON.stringify({
                eventid: this.event.id
            }))
        }
    </script>
</presence>
