/*jslint browser: true, indent: 2, nomen: true, plusplus: true, newcap: true, regexp: true, sloppy: true */
/*global $, SockJS, console, WebSocket*/
$(function () {
  var plot,
    sock = new WebSocket("ws://" + window.location.host + "/ws"),
    time = 0,
    ticks = [[], [], []],
    level1 = 0.0;

  sock.onopen = function () {
    console.log("Connected to WS server.");
  };

  sock.onmessage = function (data) {
    data = JSON.parse(data.data);
    switch (data.action) {
    case "level1":
      level1 = data.level1;
      $(".bid").html(data.level1.bid.toFixed(2));
      $(".ask").html(data.level1.ask.toFixed(2));
      $(".last").html(data.level1.last.toFixed(2));
      break;
    }
  };

  sock.onclose = function () {
    console.log("Disconnected from WS server.");
  };

  plot = $.plot("#price-chart", ticks, {
    series: {
      shadowSize: 0
    },
    yaxis: {
      min: 0
    },
    xaxis: {
      show: false
    }
  });

  // Push last, update graph
  setInterval(function () {
    time++;
    ticks[0].push([time, level1.bid]);
    ticks[1].push([time, level1.ask]);
    ticks[2].push([time, level1.last]);
    plot.setData(ticks);
    plot.draw();
  }, 1000);
});
