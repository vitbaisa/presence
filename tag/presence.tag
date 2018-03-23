<presence>
    <div class="row">
        <div class="two columns">
            <button class="button" if={event_pos > 0}
                    onclick={prev_event}>předchozí</button>
        </div>
        <div class="eight columns">
            <h5>{event.title}</h5>
            <span>{event.starts}</span>
        </div>
        <div class="two columns text-right">
            <button class="button" if={event_pos < events.length-1}
                    onclick={next_event}>další</button>
        </div>
    </ul>
    <div class="row">
        <div class="twelve columns text-center">
            <button class="button-primary" onclick={register}>Budu tam!</button>
        </div>
    </div>
    <div class="row">
        <div class="six columns">
            <table class="table u-full-width">
                <thead>
                    <tr>
                        <th></th>
                        <th>Hráč</th>
                        <th>Přihlášen</th>
                    </tr>
                </thead>
                <tbody>
                    <tr each={item, i in presence}>
                        <td>{i+1}</td>
                        <td>{item.username}</td>
                        <td>{item.datetime}</td>
                    </tr>
                </tbody>
            </table>
        </div>
        <div class="six columns">
            <form>
                <div class="row">
                    <textarea class="u-full-width"
                            onchange={changed_area}></textarea>
                </div>
                <div class="row">
                    <div class="twelve columns text-right">
                        <input type="submit" class="button" value="Přidat komentář" />
                    </div>
                </div>
            </form>
            <div class="row comment" each={comment in comments}>
                <p>{comment.text}</p>
                <span>{comment.userid} (comment.datetime}</span>
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
        this.eventid = null
        this.comments = []
        this.presence = []
        this.event_pos = 0
        this.userid = ''

        session() {
            $.ajax({
                url: cgi + '/session',
                success: (d) => {
                    console.log(d)
                }
            })
        }

        prev_event() {
            this.event_pos = Math.max(0, this.event_pos-1)
            this.event = this.events[this.event_pos]
            this.eventid = this.event.eventid
            this.get_comments(this.eventid)
            this.get_presence(this.eventid)
            this.update()
        }

        next_event() {
            this.event_pos = Math.min(this.events.length-1, this.event_pos+1)
            this.event = this.events[this.event_pos]
            this.eventid = this.event.eventid
            this.get_comments(this.eventid)
            this.get_presence(this.eventid)
            this.update()
        }

        get_presence(eventid) {
            $.ajax({
                url: cgi + '/presence?eventid=' + eventid,
                success: (d) => {
                    this.presence = d.data
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
                    this.get_presence(this.eventid)
                    this.get_comments(this.eventid)
                    this.update()
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

        register(userid, eventid) {
            $.ajax({
                url: cgi + '/register?userid=' + userid + '&eventid=' + eventid,
                success: (d) => {
                    console.log(d)
                    this.presence(this.eventid)
                },
                error: (d) => {
                    console.log(d)
                }
            })
        }
    </script>
</presence>
