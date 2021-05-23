<presence>
  <div>
    <ul class="tabs">
      <li style="width: {100/events.length}%"
          onclick={change_event}
          class={
            selected: location.hash == ('#ev' + ev.id) || (!location.hash.length && i == 0),
            junior: ev.junior,
          }
          each={ev, i in events} id="ev{ev.id}">
        <span>{ev.title}{ev.pinned ? "📌" : ""}</span>
      </li>
      <li if={!events.length} style="width: 100%">
        <span class="secondary-text">Žádná naplánovaná událost...</span>
      </li>
    </ul>
  </div>
  <div class="row tab" if={events.length}>
    <div class="col s12 l6">
      <div class="card">
        <div class="card-content">
          <div class="card-title">
            <span>{event.starts.slice(0, -3)}</span>
            <button if={registered}
                class="secondary-bg float-right"
                onclick={delete_presence.bind(this, this.user.id, "", event.id)}>Odhlásit</button>
            <button
                class="float-right"
                if={!registered && presence.length < event.capacity && !event.locked}
                onclick={register}>Přihlásit</button>
          </div>
          <p if={!registered && presence.length >= event.capacity}
              class="red-text">
            Termín je již plně obsazen.
          </p>
          <p if={!registered && event.locked}
              class="red-text">
            Nelze se přihlašovat méně než {event.in_advance} hodin předem.
          </p>
          <table class="striped">
            <tbody>
              <tr each={item, i in presence}>
                <td class="grey-text">{i+1}</td>
                <td 
                  title={item.datetime}
                  class={
                    bold: item.userid == user.username,
                    secondary-text: item.coach && event.junior
                  }>{item.name || item.nickname || item.username}
                  <span if={item.name}>(host)</span>
                  <span if={event.junior && item.coach}>(trenér)</span>
                  <button if={user.admin}
                      style="height: 1.2em; line-height: 1.2em"
                      onclick={delete_presence.bind(this, item.userid, item.name, event.id)}
                      class="red-text flat">✕</button>
                </td>
              </tr>
              <tr if={user.admin}>
                <td class="grey-text">{presence.length + 1}</td>
                <td>
                  <input type="text" placeholder="Lee Chong Wei" ref="guest" />
                  <br />
                  <button onclick={add_guest}>Přidat hosta</button>
                </td>
              </tr>
            </tbody>
          </table>
          <div class="row">
            <div class="col s12">
              kapacita:
              <div if={user.admin} style="display: inline-block;">
                <input type="number" min="1" max="50"
                    style="width: auto; margin-right: 1em;" size="2"
                    onchange={update_capacity}
                    ref="ccapacity" value={event.capacity} />
              </div>
              <span if={!user.admin}>{event.capacity},</span>
              kurty:
              <div if={user.admin} style="display: inline-block;">
                <input type="number" min="1" max="6"
                    style="width: auto;" size="1"
                    onchange={change_courts}
                    ref="ccourts" value={event.courts} />
              </div>
              <span if={!user.admin}>{event.courts}</span>
            </div>
          </div>
        </div>
      </div>
    </div>
    <div class="col s12 l6">
      <div class="card">
        <div class="card-content">
          <div class="card-title">Komentáře</div>
          <ul class="comments">
            <li each={c in comments}>
              <p>
                <b title={c.datetime}>{c.nickname || c.username}</b>:
                {decodeURIComponent(c.text)}
              </p>
            </li>
          </ul>
          <form class="text-right">
            <textarea onchange={changed_area} ref="new_comment"></textarea>
            <button onclick={add_comment}>Přidat komentář</button>
          </form>
        </div>
      </div>
    </div>
  </div>
  <div class="row" if={user.admin}>
    <div class="col s12">
      <div class="card">
        <div class="card-content">
          <div class="card-title">
            Kdo vidí a může se přihlásit na zobrazený termín
          </div>
          <div class="col s6" each={u in users} style="white-space: nowrap;">
            <input type="checkbox" id="att_{u.id}"
                checked={event && event.restriction && event.restriction.indexOf(u.id) >= 0}
                onchange={changeRestriction} />
            <label for="att_{u.id}">{u.nickname || u.username}</label>
          </div>
        </div>
      </div>
    </div>
  </div>
  <div if={user.admin} style="padding-top: .5em;">
    <ul class="tabs">
      <li style="width: {100/admin_tabs.length}%"
          each={tab in admin_tabs}
          class={selected: admin_tab == tab.id}
          onclick={change_admin_tab.bind(this, tab.id)}>
        <span>{tab.label}</span>
      </li>
    </ul>
  </div>
  <div class="row tab" if={admin_tab == "new_event" && user.admin}>
    <div class="col s12">
      <div class="card">
        <div class="card-content">
          <div class="row">
            <div class="col s12 m6 input-field">
              <input type="text" ref="eventname" required placeholder="Název akce" />
              <label>Název akce</label>
            </div>
            <div class="col s6 m3 input-field">
              <input type="text" ref="date_starts" value={new Date().toISOString().slice(0, 10)} />
              <label>Datum začátku</label>
            </div>
            <div class="col s6 m3 input-field">
              <input type="text" ref="time_starts" value="19:00:00" />
              <label>Čas začátku</label>
            </div>
            <div class="col s6 m3 input-field">
              <input type="number" ref="duration" value="2" />
              <label>Trvání</label>
            </div>
            <div class="col s6 m3 input-field">
              <input type="text" value="Zetor" ref="nlocation" />
              <label>Místo</label>
            </div>
            <div class="col s6 m3 input-field">
              <input type="number" min="1" ref="ncourts" value="4" />
              <label>Kurty</label>
            </div>
            <div class="col s6 m3 input-field">
              <input type="number" min="1" ref="ncapacity" value="16" />
              <label>Kapacita</label>
            </div>
            <div class="col s6 m3 input-field">
              <input type="checkbox" id="pinned" style="height: 3em;" />
              <label for="pinned" class="active">Připnout</label>
            </div>
            <div class="col s6 m3 input-field">
              <input type="checkbox" id="junior" style="height: 3em" />
              <label for="junior" class="active">Junioři</label>
            </div>
          </div>
          <div class="row">
            <div class="col s12">
              <div class="row">
                <div class="col s6 l3">
                  <input type="checkbox" checked id="all" onchange={check_all} />
                  <label for="all" class="active">Všichni</label>
                </div>
                <div class="col s6 l3" each={u in users}>
                  <input type="checkbox" id={"uid_" + u.id} data-id={u.id} />
                  <label for={"uid_" + u.id}>{decodeURIComponent(u.nickname || u.username)}</label>
                </div>
              </div>
            </div>
          </div>
          <div class="row">
            <div class="col s12">
              <button onclick={create_event}>Vytvořit</button>
            </div>
          </div>
        </div>
      </div>
    </div>
  </div>
  <div class="row tab" if={admin_tab == "recurrent_events" && user.admin}>
    <div class="col s12">
      <div class="card">
        <div class="card-content">
          <p>POZOR: Změny v této tabulce se projeví nejdřív za týden.</p>
          <div class="row">
            <div class="col s12">
              <select onchange={change_ce_tab}>
                <option each={item, idx in recurrent_events}
                  value={idx} selected={ce_tab == idx}>{item.title}</option>
              </select>
            </div>
          </div>
          <div class="row tab" each={item, idx in recurrent_events} if={ce_tab == idx}>
            <div class="col s6 m4 input-field">
              <select name="day" class="browser-default" onchange={changeCE}>
                <option each={day, dayidx in days} value={dayidx}
                    selected={item.day == dayidx}>{day}</option>
              </select>
            </div>
            <div class="col s6 m4 input-field">
              <input type="text" name="title" value={item.title} onchange={changeCE} />
            </div>
            <div class="col s6 m4 input-field">
              <input type="text" name="location" value={item.location} onchange={changeCE} />
            </div>
            <div class="col s6 m4 input-field">
              <input type="text" name="starts" value={item.starts} onchange={changeCE} />
            </div>
            <div class="col s4 m2 input-field">
              <input name="duration" type="number" min="1" max="12" value={item.duration} onchange={changeCE} />
            </div>
            <div class="col s4 m2 input-field">
              <input name="capacity" type="number" min="1" max="50"
                  value={item.capacity} onchange={changeCE} />
            </div>
            <div class="col s4 m2 input-field">
              <input name="courts" type="number" min="1" max="6"
                  value={item.courts} onchange={changeCE} /></td>
            </div>
          </div>
          <div class="row tab" each={item, idx in recurrent_events}
              if={ce_tab == idx}>
            <div class="col s6 m4 l3" each={u in users} style="white-space: nowrap;">
              <input type="checkbox" id="ce_{idx}_{u.id}"
                  checked={item.restriction.indexOf(u.id.toString()) >= 0}
                  onchange={changeCronEventRestriction} />
              <label for="ce_{idx}_{u.id}">{decodeURIComponent(u.nickname || u.username)}</label>
            </div>
          </div>
        </div>
      </div>
    </div>
  </div>
  <div class="row tab" if={user.admin && admin_tab == "new_user"}>
    <div class="col s12">
      <div class="card">
        <div class="card-content">
          <div class="row">
            <div class="col s6 m3 input-field">
              <input type="text" ref="newusername" placeholder="zuzana.ruzickova" />
              <label>Uživatelské jméno</label>
            </div>
            <div class="col s6 m3 input-field">
              <input type="text" ref="nickname" placeholder="Zuzana Růžičková" />
              <label>Celé jméno</label>
            </div>
            <div class="col s6 m3 input-field">
              <input ref="password" type="password" />
              <label>Heslo</label>
            </div>
            <div class="col s12 text-right">
              <button onclick={add_user}>Přidat hráče</button>
            </div>
          </div>
        </div>
      </div>
    </div>
  </div>

  <style>
    .btn, button {
        border: none;
        border-radius: 2px;
        display: inline-block;
        height: 36px;
        line-height: 36px;
        padding: 0 2rem;
        text-transform: uppercase;
        vertical-align: middle;
      }
      .row {
        margin-left: auto;
        margin-right: auto;
        margin-bottom: 20px;
      }
      .row:after {
        content: "";
        display: table;
        clear: both;
      }
      .row .col {
        float: left;
        -webkit-box-sizing: border-box;
                box-sizing: border-box;
        padding: 0 0.75rem;
        min-height: 1px;
      }
      .row .col.s1 {
        width: 8.3333333333%;
        margin-left: auto;
        left: auto;
        right: auto;
      }
      .row .col.s2 {
        width: 16.6666666667%;
        margin-left: auto;
        left: auto;
        right: auto;
      }
      .row .col.s3 {
        width: 25%;
        margin-left: auto;
        left: auto;
        right: auto;
      }
      .row .col.s4 {
        width: 33.3333333333%;
        margin-left: auto;
        left: auto;
        right: auto;
      }
      .row .col.s5 {
        width: 41.6666666667%;
        margin-left: auto;
        left: auto;
        right: auto;
      }
      .row .col.s6 {
        width: 50%;
        margin-left: auto;
        left: auto;
        right: auto;
      }
      .row .col.s7 {
        width: 58.3333333333%;
        margin-left: auto;
        left: auto;
        right: auto;
      }
      .row .col.s8 {
        width: 66.6666666667%;
        margin-left: auto;
        left: auto;
        right: auto;
      }
      .row .col.s9 {
        width: 75%;
        margin-left: auto;
        left: auto;
        right: auto;
      }
      .row .col.s10 {
        width: 83.3333333333%;
        margin-left: auto;
        left: auto;
        right: auto;
      }
      .row .col.s11 {
        width: 91.6666666667%;
        margin-left: auto;
        left: auto;
        right: auto;
      }
      .row .col.s12 {
        width: 100%;
        margin-left: auto;
        left: auto;
        right: auto;
      }
      @media only screen and (min-width: 601px) {
        .row .col.m1 {
          width: 8.3333333333%;
          margin-left: auto;
          left: auto;
          right: auto;
        }
        .row .col.m2 {
          width: 16.6666666667%;
          margin-left: auto;
          left: auto;
          right: auto;
        }
        .row .col.m3 {
          width: 25%;
          margin-left: auto;
          left: auto;
          right: auto;
        }
        .row .col.m4 {
          width: 33.3333333333%;
          margin-left: auto;
          left: auto;
          right: auto;
        }
        .row .col.m5 {
          width: 41.6666666667%;
          margin-left: auto;
          left: auto;
          right: auto;
        }
        .row .col.m6 {
          width: 50%;
          margin-left: auto;
          left: auto;
          right: auto;
        }
        .row .col.m7 {
          width: 58.3333333333%;
          margin-left: auto;
          left: auto;
          right: auto;
        }
        .row .col.m8 {
          width: 66.6666666667%;
          margin-left: auto;
          left: auto;
          right: auto;
        }
        .row .col.m9 {
          width: 75%;
          margin-left: auto;
          left: auto;
          right: auto;
        }
        .row .col.m10 {
          width: 83.3333333333%;
          margin-left: auto;
          left: auto;
          right: auto;
        }
        .row .col.m11 {
          width: 91.6666666667%;
          margin-left: auto;
          left: auto;
          right: auto;
        }
        .row .col.m12 {
          width: 100%;
          margin-left: auto;
          left: auto;
          right: auto;
        }
      }
      @media only screen and (min-width: 993px) {
        .row .col.l1 {
          width: 8.3333333333%;
          margin-left: auto;
          left: auto;
          right: auto;
        }
        .row .col.l2 {
          width: 16.6666666667%;
          margin-left: auto;
          left: auto;
          right: auto;
        }
        .row .col.l3 {
          width: 25%;
          margin-left: auto;
          left: auto;
          right: auto;
        }
        .row .col.l4 {
          width: 33.3333333333%;
          margin-left: auto;
          left: auto;
          right: auto;
        }
        .row .col.l5 {
          width: 41.6666666667%;
          margin-left: auto;
          left: auto;
          right: auto;
        }
        .row .col.l6 {
          width: 50%;
          margin-left: auto;
          left: auto;
          right: auto;
        }
        .row .col.l7 {
          width: 58.3333333333%;
          margin-left: auto;
          left: auto;
          right: auto;
        }
        .row .col.l8 {
          width: 66.6666666667%;
          margin-left: auto;
          left: auto;
          right: auto;
        }
        .row .col.l9 {
          width: 75%;
          margin-left: auto;
          left: auto;
          right: auto;
        }
        .row .col.l10 {
          width: 83.3333333333%;
          margin-left: auto;
          left: auto;
          right: auto;
        }
        .row .col.l11 {
          width: 91.6666666667%;
          margin-left: auto;
          left: auto;
          right: auto;
        }
        .row .col.l12 {
          width: 100%;
          margin-left: auto;
          left: auto;
          right: auto;
        }
      }
      .center {
        text-align: center;
      }
      .right-align {
        text-align: right;
      }
      .card {
        position: relative;
        margin: 0.5rem 0 1rem 0;
        background-color: #fff;
        -webkit-transition: -webkit-box-shadow .25s;
        transition: -webkit-box-shadow .25s;
        transition: box-shadow .25s;
        transition: box-shadow .25s, -webkit-box-shadow .25s;
        border-radius: 2px;
      }
      .card .card-title {
        font-size: 24px;
        font-weight: 300;
      }
      .card .card-content {
        padding: 24px;
        border-radius: 0 0 2px 2px;
        overflow: auto;
      }
      label {
        font-size: 0.8rem;
        color: #9e9e9e;
      }
      .card, .btn {
        -webkit-box-shadow: 0 2px 2px 0 rgba(0, 0, 0, 0.14), 0 1px 5px 0 rgba(0, 0, 0, 0.12), 0 3px 1px -2px rgba(0, 0, 0, 0.2);
                box-shadow: 0 2px 2px 0 rgba(0, 0, 0, 0.14), 0 1px 5px 0 rgba(0, 0, 0, 0.12), 0 3px 1px -2px rgba(0, 0, 0, 0.2);
      }
      .btn:hover {
        -webkit-box-shadow: 0 3px 3px 0 rgba(0, 0, 0, 0.14), 0 1px 7px 0 rgba(0, 0, 0, 0.12), 0 3px 1px -1px rgba(0, 0, 0, 0.2);
                box-shadow: 0 3px 3px 0 rgba(0, 0, 0, 0.14), 0 1px 7px 0 rgba(0, 0, 0, 0.12), 0 3px 1px -1px rgba(0, 0, 0, 0.2);
      }
      html {
        line-height: 1.5;
        font-family: "Roboto", sans-serif;
        font-weight: normal;
        color: rgba(0, 0, 0, 0.87);
      }
      @media only screen and (min-width: 0) {
        html {
          font-size: 14px;
        }
      }
      @media only screen and (min-width: 992px) {
        html {
          font-size: 14.5px;
        }
      }
      @media only screen and (min-width: 1200px) {
        html {
          font-size: 15px;
        }
      }
      body {
        margin: 0;
      }
      a {
        color: #039be5;
        text-decoration: none;
        -webkit-tap-highlight-color: transparent;
      }
      .btn {
        font-size: 1rem;
        outline: 0;
      }
      .btn:focus {
        background-color: #1d7d74;
      }
      .btn {
        text-decoration: none;
        color: #fff;
        background-color: #26a69a;
        text-align: center;
        letter-spacing: .5px;
        -webkit-transition: .2s ease-out;
        transition: .2s ease-out;
        cursor: pointer;
      }
      .btn:hover, .btn-large:hover {
        background-color: #2bbbad;
      }
      ::placeholder {
        color: #d1d1d1;
      }

    /* END MATERIALIZE DEFINITION */
    ul.comments {
      margin: 0;
      padding: 0;
      list-style-type: none;
    }
    table {
      width: 100%;
      margin-top: 1em;
      border-collapse: collapse;
      border: none;
    }
    table.striped > tbody > tr:nth-child(2n+1) {
      background-color: #f2f2f2;
    }
    th,
    td {
      padding: .5em;
    }
    .secondary-bg {
      background-color: crimson;
    }
    .secondary-text {
      color: crimson;
    }
    .float-right {
      float: right;
    }
    button.flat {
      background-color: transparent;
      padding: 0;
    }
    button {
      margin-top: 2px;
      font-size: .9rem;
      text-decoration: none;
      color: white;
      background-color: #1975FA;
      text-align: center;
      letter-spacing: .5px;
      cursor: pointer;
      border: none;
      border-radius: 2px;
      display: inline-block;
      height: 36px;
      line-height: 36px;
      padding: 0 1rem;
      text-transform: uppercase;
      vertical-align: middle;
      white-space: nowrap;
    }
    .row {
      margin: 0 auto 20px auto;
      max-width: 1000px;
    }
    .row .col {
      float: left;
      box-sizing: border-box;
      padding: 0 0.75rem;
      min-height: 1px;
    }
    .row .col.s12 {
      width: 100%;
      margin-left: auto;
    }
    a {
      text-decoration: none;
    }
    input[type="number"] {
      border: none;
      padding: .5em;
    }
    input[type="text"],
    input[type="password"],
    input[type="number"] {
      background-color: transparent;
      border: none;
      border-bottom: 1px solid #9e9e9e;
      border-radius: 0;
      outline: none;
      height: 3rem;
      width: 100%;
      font-size: 1rem;
      margin: 0 0 20px 0;
      padding: 0;
      box-shadow: none;
      box-sizing: content-box;
    }
    .input-field {
      position: relative;
    }
    .input-field label {
      color: #9e9e9e;
      position: absolute;
      top: -.3em;
      left: 1em;
      font-size: .75rem;
      transform-origin: 0% 100%;
      text-align: initial;
    }
    textarea {
      border: solid 1px #EEE;
      background-color: #F9F9F9;
      margin-top: 1em;
      padding: 1rem;
      width: 100%;
      resize: none;
      min-height: 3rem;
      box-sizing: border-box;
    }
    .card,
    .card-panel {
      box-shadow: 0 1px 1px 0 rgba(0, 0, 0, 0.14), 0 1px 5px 0 rgba(0, 0, 0, 0.12), 0 3px 1px -2px rgba(0, 0, 0, 0.2);
    }
    @media only screen and (min-width: 993px) { /* large */
      .row .col.l6 {
        width: 50%;
        left: auto;
        right: auto;
      }
    }
    @media only screen and (max-width: 600px) { /* medium */
      .row .col.m6 {
        width: 50%;
        left: auto;
        right: auto;
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
    .red-text {
      color: red;
    }
    .grey-text {
      color: #AAA;
    }
    .tabs {
      position: relative;
      line-height: 48px;
      width: 100%;
      margin: 0 auto;
      display: flex;
      flex-direction: row;
      padding-left: 0;
      list-style-type: none;
    }
    .tabs > li {
      display: inline-block;
      cursor: pointer;
      text-align: center;
      line-height: 48px;
      height: 48px;
      padding: 0;
      margin: 0;
      border: 1px solid #D6D6D6;
      border-top: solid 2px #CCC;
      background-color: #EEE;
      white-space: nowrap;
      overflow-x: hidden;
    }
    .tabs > li.selected {
      border-bottom: none;
      border-top: solid 2px #1975FA;
      background-color: #F9F9F9;
    }
    .tabs > li span {
      padding: 0 .5em;
      font-size: 14px;
      text-overflow: ellipsis;
      overflow: hidden;
    }
    .tabs > li.junior {
      border-top: solid 2px #4095b7;
    }
    .nowrap {
      white-space: nowrap;
    }
    .text-right {
      text-align: right;
    }
  </style>

  <script>
    this.event = null
    this.events = []
    this.comments = []
    this.presence = []
    this.user = {}
    this.users = []
    this.recurrent_events = []
    this.days = ["Pondělí", "Úterý", "Středa", "Čtvrtek", "Pátek", "Sobota", "Neděle", "Neopakuje se"]
    this.admin_tab = "new_event"
    this.admin_tabs = [
        {id: "new_event", label: "Nová událost"},
        {id: "recurrent_events", label: "Opakující se události"},
        {id: "new_user", label: "Nový hráč"},
    ]
    this.ce_tab = 0
    this.registered = false

    change_admin_tab(tab) {
      this.admin_tab = tab
    }

    change_ce_tab(e) {
      this.ce_tab = e.target.selectedIndex
    }

    is_registered() {
      for (let i=0; i<this.presence.length; i++) {
          if (this.presence[i].userid >= 0 && this.user.id == this.presence[i].userid) {
              return true
        }
      }
      return false
    }

    add_user(event) {
      event.preventDefault()
      let xhr = new XMLHttpRequest()
      xhr.withCredentials = true
      xhr.onload = function () {
        this.refs.newusername.value = ""
        this.refs.nickname.value = ""
        this.refs.password.value = ""
        if (xhr.status === 200) {
          this.get_users()
        }
      }.bind(this)
      xhr.open('POST', "/user")
      xhr.setRequestHeader('Content-Type', 'application/json');
      xhr.send(JSON.stringify({
        newusername: this.refs.newusername.value,
        nickname: this.refs.nickname.value,
        password: this.refs.password.value,
      }))
    }

    changeCE(e) {
      this.recurrent_events[this.ce_tab][e.target.name] = e.target.value
      if (e.target.name == "day") {
        this.recurrent_events[this.ce_tab][e.target.name] = parseInt(e.target.value)
      }
      this.set_recurrent_events()
    }

    get_users() {
      let xhr = new XMLHttpRequest()
      xhr.withCredentials = true
      xhr.onload = function () {
        let payload = JSON.parse(xhr.responseText)
        this.users = payload.data
        this.update()
      }.bind(this)
      xhr.open('GET', "/users")
      xhr.send()
    }
    this.get_users()

    get_recurrent_events() {
      let xhr = new XMLHttpRequest()
      xhr.withCredentials = true
      xhr.onload = function () {
        if (xhr.status === 200) {
          let payload = JSON.parse(xhr.responseText)
          this.recurrent_events = payload.data.events
          this.update()
        }
      }.bind(this)
      xhr.open("GET", "/recurrent_events")
      xhr.send()
    }

    set_recurrent_events() {
      let xhr = new XMLHttpRequest()
      xhr.withCredentials = true
      xhr.onload = function () {
        if (xhr.status === 200) {
          let payload = JSON.parse(xhr.responseText)
          this.reccurent_events = payload.data.events
          this.update()
        }
      }.bind(this)
      xhr.open("POST", "/recurrent_events")
      xhr.setRequestHeader('Content-Type', 'application/json');
      xhr.send(JSON.stringify({data: {events: this.recurrent_events}}))
    }

    changeCronEventRestriction(ev) {
      let uid = ev.item.u.id.toString()
      let idx = this.ce_tab
      if (ev.currentTarget.checked) {
        if (this.recurrent_events[idx].restriction.indexOf(uid) == -1) {
          this.recurrent_events[idx].restriction.push(uid)
          this.recurrent_events[idx].restriction.sort()
        }
      }
      else {
        let ind = this.recurrent_events[idx].restriction.indexOf(uid)
        if (ind != -1) {
          this.recurrent_events[idx].restriction.splice(ind, 1)
        }
      }
      this.set_recurrent_events()
    }

    changeRestriction(ev) {
      let uid = ev.item.u.id
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
      let xhr = new XMLHttpRequest()
      xhr.withCredentials = true
      xhr.onload = function () {}
      xhr.open('POST', "/restriction")
      xhr.setRequestHeader('Content-Type', 'application/json');
      xhr.send(JSON.stringify({
        eventid: this.event.id,
        restriction: this.event.restriction.join(",")
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
      xhr.open('PUT', "/courts")
      xhr.send(JSON.stringify({
        eventid: parseInt(this.event.id),
        courts: parseInt(courts),
      }))
    }

    delete_presence(userid, name, eventid, event) {
      let xhr = new XMLHttpRequest()
      xhr.withCredentials = true
      xhr.onload = function () {
        this.get_presence()
      }.bind(this)
      xhr.open('DELETE', "/register")
      xhr.send(JSON.stringify({
        userid: name ? -1 : parseInt(userid),
        name: name,
        eventid: parseInt(eventid),
      }))
    }

    update_capacity(ev) {
      let xhr = new XMLHttpRequest()
      xhr.withCredentials = true
      xhr.onload = function () {
        this.event.capacity = this.refs.ccapacity.value
        this.update()
      }.bind(this)
      xhr.open('PUT', "/capacity")
      xhr.send(JSON.stringify({
        eventid: this.event.id,
        capacity: this.refs.ccapacity.value,
      }))
    }

    pin_event(event) {
      if (event.target.checked) {
        let xhr = new XMLHttpRequest()
        xhr.withCredentials = true
        xhr.onload = function () {
          this.event.pinned = event.target.checked
          this.update()
        }.bind(this)
        xhr.open('PUT', "/event")
        xhr.send(JSON.stringify({
          eventid: this.event.id,
          name: "pinned",
          value: parseInt(event.target.checked),
        }))
      }
    }

    check_all(ev) {
      let is_checked = document.querySelectorAll('input#all:not(:checked)').length
      document.querySelectorAll('input[id^="uid_"]').forEach(function (i) {
        i.checked = !is_checked
      })
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
      if (document.querySelectorAll('input#all:not(:checked)').length) {
        let userarray = []
        document.querySelectorAll('input[id^="uid_"]:checked').forEach(function (e) {
          userarray.push(e.dataset.id)
        })
      }
      let pinned = document.getElementById("pinned").checked
      let junior = document.getElementById("junior").checked
      let xhr = new XMLHttpRequest()
      xhr.withCredentials = true
      xhr.onload = function () {
        // reset form
        this.refs.eventname.value = ""
        this.refs.date_starts.value = ""
        this.get_events()
      }.bind(this)
      xhr.open('POST', "/event")
      xhr.setRequestHeader('Content-Type', 'application/json');
      xhr.send(JSON.stringify({
        title: this.refs.eventname.value,
        starts: this.refs.date_starts.value + " " + this.refs.time_starts.value,
        duration: parseInt(this.refs.duration.value),
        restriction: userarray,
        location: this.refs.nlocation.value,
        capacity: parseInt(this.refs.ncapacity.value),
        courts: parseInt(this.refs.ncourts.value),
        junior: junior ? 1 : 0,
        pinned: pinned ? 1 : 0,
      }))
    }

    get_user() {
      let xhr = new XMLHttpRequest()
      xhr.withCredentials = true
      xhr.onload = function () {
        this.user = JSON.parse(xhr.responseText)
        if (this.user.warning) {
            alert("Napiš na vit.baisa@gmail.com, vyskytl se problém s tvým uživatelským jménem.")
        }
        this.user.admin && !(this.recurrent_events.length) && this.get_recurrent_events()
        this.update()
      }.bind(this)
      xhr.open('GET', "/user")
      xhr.send()
    }

    get_presence() {
      let xhr = new XMLHttpRequest()
      xhr.withCredentials = true
      xhr.onload = function () {
        let d = JSON.parse(xhr.responseText)
        this.presence = d.data
        this.registered = this.is_registered()
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
      xhr.open('POST', "/guest")
      xhr.setRequestHeader('Content-Type', 'application/json');
      xhr.send(JSON.stringify({
        eventid: parseInt(this.event.id),
        name: name,
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
      xhr.setRequestHeader('Content-Type', 'application/json');
      xhr.send(JSON.stringify({
        eventid: parseInt(this.event.id),
        comment: comment
      }))
    }

    get_events() {
      let xhr = new XMLHttpRequest()
      xhr.withCredentials = true
      xhr.onload = function () {
        let d = JSON.parse(xhr.responseText)
        if (!d.data.length) {
          this.events = []
          this.user.admin && this.get_recurrent_events()
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
        if (this.events.length) {
            this.event = this.events[ind]
            this.get_presence()
            this.get_comments()
        }
        this.user.admin && this.get_recurrent_events()
        this.update()
      }.bind(this)
      xhr.open('GET', "/events")
      xhr.send()
    }
    this.get_events()

    get_comments() {
      let xhr = new XMLHttpRequest()
      xhr.withCredentials = true
      xhr.onload = function () {
        this.comments = JSON.parse(xhr.responseText).data
        this.update()
      }.bind(this)
      xhr.open('GET', "/comments?eventid=" + this.event.id)
      xhr.send()
    }

    register() {
      let xhr = new XMLHttpRequest()
      xhr.withCredentials = true
      xhr.onload = function () {
        // remove
        this.get_presence()
      }.bind(this)
      xhr.open('POST', "/register")
      xhr.setRequestHeader('Content-Type', 'application/json');
      xhr.send(JSON.stringify({
        eventid: this.event.id
      }))
    }

    this.on("mount", function (d) {
      this.get_user()
    })
  </script>
</presence>
