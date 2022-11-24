<template>
<p v-if="ticking">
    <v-row justify="center" class="timer-box">
        <div>
            <span id="days" class="mb-n3"></span><br>
            <small>Days</small>
        </div>
        <div>
            <span id="hours"></span>
            <small>Hours</small>

        </div>
        <div>
            <span id="mins"></span><br>
            <small>Mins</small>

        </div>
        <div>
            <span id="secs"></span><br>
            <small>Secs</small>

        </div>
    </v-row>
</p>
</template>

<script>
export default {
    props: {
        countDownDate: {
            Type: Date,
            required: true
        }
    },
    data() {
        return {
            ticking: true
        }
    },
    computed: {
        presale() {
            return this.$store.state.mint.presale
        }
    },
    mounted() {
        this.startTimer()

    },
    methods: {
        startTimer() {
            var x = setInterval(() => {

                var now = new Date().getTime();

                var distance = this.countDownDate - now;

                var days = Math.floor(distance / (1000 * 60 * 60 * 24));
                var hours = Math.floor((distance % (1000 * 60 * 60 * 24)) / (1000 * 60 * 60));
                var minutes = Math.floor((distance % (1000 * 60 * 60)) / (1000 * 60));
                var seconds = Math.floor((distance % (1000 * 60)) / 1000);

                document.getElementById("days").innerHTML = days
                document.getElementById("hours").innerHTML = hours
                document.getElementById("mins").innerHTML = minutes
                document.getElementById("secs").innerHTML = seconds

                if (distance < 0) {
                    clearInterval(x);
                    this.$store.commit('mint/setLiveTrue')
                    this.$store.commit('mint/setPresaleTrue')
                    this.$store.commit('mint/setPublicMintTrue')
                }
            }, 1000);
        }
    }
}
</script>

<style>
.timer-box div {
    width: 35px;
    height: 43px;
    margin: 10px 5px;
    background: linear-gradient(180deg, #434343 0%, #000000 100%);
}

.timer-box div small {
    font-size: x-small;
    margin-top: -10px;
}
</style>
