/*jslint browser: true, indent: 2, nomen: true, plusplus: true, newcap: true, regexp: true, sloppy: true */
/*global $, SockJS, console, WebSocket*/
function connect() {
  var plot, refreshTimer, connectTimer,
    NumPeriods = 300,
    UpdateInterval = 100,
    sock = new WebSocket("ws://" + window.location.host + "/ws"),
    time = 0,
    ticks = {
      bids: [],
      asks: [],
      lasts: []
    },
    level1 = 0.0;

  sock.onopen = function () {
    console.log("Connected to WS server.");
    clearTimeout(connectTimer);
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
    case "accounts":
      $("#leaderboard tbody").html(
        $.map(data.accounts, function (obj) {
          obj[1] = obj[1].toFixed(2);
          obj[3] = obj[3].toFixed(2);
          return "<tr><td>" + obj.join("</td><td>") + "</td></tr>";
        }).join("")
      );
      break;
    }
  };

  sock.onclose = function () {
    console.log("Disconnected from WS server.");
    // reconnect in 10 seconds
    clearInterval(refreshTimer);
    connectTimer = setTimeout(connect, 10000);
  };

  function getData() {
    return [
      {
        data: ticks.bids,
        label: "Bid"
      },
      {
        data: ticks.asks,
        label: "Ask"
      },
      {
        data: ticks.lasts,
        label: "Last"
      }
    ];
  }

  plot = $.plot("#price-chart", getData(), {
    series: {
      shadowSize: 0
    },
    xaxis: {
      show: false
    }
  });

  // Push last, update graph
  refreshTimer = setInterval(function () {
    time++;
    ticks.bids.push([time, level1.bid > 0 ? level1.bid : null]);
    ticks.asks.push([time, level1.ask > 0 ? level1.ask : null]);
    ticks.lasts.push([time, level1.last > 0 ? level1.last : null]);

    // strip off older ones
    while (ticks.bids.length > 0 && ticks.bids[0][0] < time - NumPeriods) {
      ticks.bids.shift();
    }
    while (ticks.asks.length > 0 && ticks.asks[0][0] < time - NumPeriods) {
      ticks.asks.shift();
    }
    while (ticks.lasts.length > 0 && ticks.lasts[0][0] < time - NumPeriods) {
      ticks.lasts.shift();
    }

    plot.setData(getData());
    plot.setupGrid();
    plot.draw();
  }, UpdateInterval);
}

$(function () {
  connect();
});
