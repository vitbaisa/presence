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
            <span>{event.title}
              <span class="start">{event.start}</span>
            </span>
            <button if={is_registered()}
                class="secondary-bg float-right"
                onclick={unregister}>Odhlásit</button>
            <button
                class="float-right"
                if={!is_registered() && presence.length < event.capacity && !event.locked}
                onclick={register}>Přihlásit</button>
          </div>
          <p if={!is_registered() && presence.length >= event.capacity}
              class="red-text">
            Termín je již plně obsazen.
          </p>
          <p if={!is_registered() && event.locked}
              class="red-text">
            Nelze se přihlašovat méně než {event.in_advance} hodin předem.
          </p>
          <table class="striped">
            <tbody>
              <tr each={item, i in presence}>
                <td>{i+1}</td>
                <td class={
                    bold: item.userid == user.username,
                    secondary-text: item.coach && event.junior
                  }>{item.name || item.fullname || item.username}
                  <span if={item.name}>(host)</span>
                  <span if={event.junior && item.coach}>(trenér)</span>
                  <button if={user.admin}
                      onclick={delete_user}
                      class="red-text flat">✕</button>
                </td>
                <td class="text-right nowrap">{item.datetime}</td>
              </tr>
              <tr if={user.admin}>
                <td>{presence.length + 1}</td>
                <td>
                  <input type="text"
                      placeholder="Lee Chong Wei"
                      ref="guest" />
                </td>
                <td class="text-right">
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
          <div class="card-title">Komentáře</div>
          <ul class="comments">
            <li each={c in comments}>
              <span class="author">{c.name}</span>  
              <span>{decodeURIComponent(c.text)}</span>
              <span class="comment-detail">{c.datetime}</span>
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
  <div if={user.admin} class="row" style="padding-top: .5em;">
    <ul class="tabs">
      <li style="width: {100/admin_tabs.length}"
          each={tab in admin_tabs}
          class={selected: admin_tab == tab.id}"
          onclick={change_admin_tab.bind(this, tab.id)}>
        <span>{tab.label}</span>
      </li>
    </ul>
  </div>
  <div class="row tab" if={admin_tab == "new_event" && user.admin}>
    <div class="col s12">
      <div class="card">
        <div class="card-content">
          <span class="card-title">Nová událost</span>
          <div class="row">
            <div class="col s12 m6 input-field">
              <input type="text" ref="eventname" />
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
              <input type="text" ref="date_ends" value={new Date().toISOString().slice(0, 10)} />
              <label>Datum konce</label>
            </div>
            <div class="col s6 m3 input-field">
              <input type="text" ref="time_ends" value="21:00:00" />
              <label>Čas konce</label>
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
              <button onclick={create_event}>Vytvořit</button>
            </div>
          </div>
        </div>
      </div>
    </div>
  </div>
  <div class="row tab" if={admin_tab == "repeating" && user.admin}>
    <div class="col s12">
      <div class="card">
        <div class="card-content">
          <div class="card-title">Opakující se události</div>
          <p>POZOR: Změny v této tabulce se projeví nejdřív za týden.
            Juniorské tréninky musí mít v názvu "JUNIOŘI"!</p>
          <ul class="tabs">
            <li each={item, idx in cronevents}
                onclick={change_ce_tab.bind(this, idx)}>
              <span>{item.title}</span>
            </li>
          </ul>
          <div class="row tab" if={ce_tab == idx}>
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
  <div class="row tab" if={user.admin && admin_tab == "new_user"}>
    <div class="col s12">
      <div class="card">
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
              <button onclick={add_user}>Přidat hráče</button>
            </div>
          </div>
        </div>
      </div>
    </div>
  </div>

  <style>
    /* FROM MATERIALIZE */
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
    ul.comments li span.author {
      font-weight: bold;
      font-size: 80%;
    }
    ul.comments li span.author:after {
      content: ":";
      padding-right: .2em;
    }
    ul.comments li span.comment-detail {
      float: right;
      font-size: 80%;
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
      height: 100%;
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
    .start {
      font-size: 45%;
      font-family: Arial, sans-serif;
      border-radius: 4px;
      padding: 2px 3px;
      background-color: #1975FA;
      color: white;
      font-weight: bold;
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
    }
    .tabs > li.selected {
      border-bottom: none;
      border-top: solid 2px #1975FA;
      background-color: #F9F9F9;
    }
    .tabs > li span {
      padding: 0 12px;
      padding: 0 24px;
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
    .text-center {
      text-align: center;
    }
    .bold {
      font-weight: bold;
    }
    /* tetrad: 9c18f9 pink f99c18 orange 76f918 green */
    /* triad: f91876 ~cyan */
  </style>

  <script>
    this.events = []
    this.comments = []
    this.presence = []
    this.user = {}
    this.users = []
    this.show_users = false
    this.cronevents = []
    this.days = ["Pondělí", "Úterý", "Středa", "Čtvrtek", "Pátek", "Sobota", "Neděle", "Neopakuje se"]
    this.admin_tab = "new_event"
    this.admin_tabs = [
        {id: "new_event", label: "Nová událost"},
        {id: "recurrent_events", label: "Opakující se události"},
        {id: "new_user", label: "Nový hráč"},
    ]
    this.ce_tab = 0

    change_admin_tab(tab) {
      this.admin_tab = tab
    }

    change_ce_tab(idx) {
      this.ce_tab = idx
    }

    is_registered() {
      // TODO!
      return true
    }

    add_user() {
      let xhr = new XMLHttpRequest()
      xhr.withCredentials = true
      xhr.onload = function () {
        if (xhr.status === 200) {
          this.get_users()
        }
      }.bind(this)
      xhr.open('POST', "/user")
      xhr.setRequestHeader('Content-Type', 'application/json');
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
      xhr.setRequestHeader('Content-Type', 'application/json');
      xhr.send(JSON.stringify({data: {events: this.cronevents}}))
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
      xhr.setRequestHeader('Content-Type', 'application/json');
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

    delete_user(event) {
      let xhr = new XMLHttpRequest()
      xhr.withCredentials = true
      xhr.onload = function () {
        this.get_presence()
      }.bind(this)
      xhr.open('DELETE', "/user")
      xhr.send(JSON.stringify({
        username: event.item.item.username
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
          value: event.target.checked,
        }))
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
        this.get_events()
      }.bind(this)
      xhr.open('POST', "/event")
      xhr.setRequestHeader('Content-Type', 'application/json');
      xhr.send(JSON.stringify({
        title: this.refs.eventname.value,
        starts: this.refs.date_starts.value + " " + this.refs.time_starts.value,
        ends: this.refs.date_ends.value + " " + this.refs.time_ends.value,
        restriction: users,
        location: this.refs.nlocation.value,
        capacity: this.refs.ncapacity.value,
        courts: this.refs.ncourts.value,
        pinned: pinned ? 1 : 0
      }))
    }

    get_user() {
      let xhr = new XMLHttpRequest()
      xhr.withCredentials = true
      xhr.onload = function () {
        this.user = JSON.parse(xhr.responseText)
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
        eventid: this.event.id,
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
        eventid: this.event.id,
        comment: encodeURIComponent(comment)
      }))
    }

    get_events() {
      let xhr = new XMLHttpRequest()
      xhr.withCredentials = true
      xhr.onload = function () {
        let d = JSON.parse(xhr.responseText)
        if (!d.data.length) {
          this.events = []
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
        this.user.admin && this.get_cronevents() // TODO!!!
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

    unregister() {
      let xhr = new XMLHttpRequest()
      xhr.withCredentials = true
      xhr.onload = function () {
        let d = JSON.parse(xhr.responseText)
        if (d.unregistered) {
            // remove unregistered
        }
      }.bind(this)
      xhr.open('DELETE', "/register")
      xhr.send(JSON.stringify({
        eventid: this.event.id
      }))
    }

    this.on("mount", function (d) {
      this.get_user()
    })
  </script>
</presence>
