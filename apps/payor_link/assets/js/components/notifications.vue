<template>
  <div class="ui simple dropdown item labeled icon">
    <i class="bell large icon"></i>
    <div class="ui red mini label circular">22</div>
    <div class="menu">
      <div class="ui basic buttons no-border borderless">
        <button class="ui active button">LOA</button>
        <button class="ui button">Claims</button>
      </div>
      <a class="item">
        Approved 
        <div class="ui notif-approved horizontal tiny circular float-right label mrg0B">5</div>
      </a>
      <a class="item">
        Pending 
        <div class="ui notif-pending horizontal tiny circular float-right label mrg0B">15</div>
      </a>
      <a class="item">
        Disapproved
        <div class="ui notif-disapproved horizontal tiny circular float-right label mrg0B">44</div>
      </a>
    </div>   
  </div>
</template>

<script>
import {Socket} from "phoenix"
export default {
  mounted() {
    this.socket = new Socket("/socket", {params: {token: window.userToken}})
    this.socket.connect()

    let channel = this.socket.channel("user:lobby", {})
    channel.join()
    .receive("ok", resp => { console.log("Joined successfully", resp) })
    .receive("error", resp => { console.log("Unable to join", resp) })
  },
  data() {
    return {
      socket: null,
      channel: null,
      notifications: []
    }
  },
  methods: {
  }
}
</script>

<style lang="sass">
</style>
