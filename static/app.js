const db = firebase.initializeApp({
  databaseURL: 'https://fb-akylab.firebaseio.com',
}).database();

const table = document.querySelector("#realtime_area").appendChild(document.createElement("table"));
const target = [
  'fitError',
  'isWalking',
  'noiseStatus',
  'powerLeft',
  'eyeMoveUp',
  'eyeMoveDown',
  'eyeMoveLeft',
  'eyeMoveRight',
  'blinkSpeed',
  'blinkStrength',
  'roll',
  'pitch',
  'yaw',
  'accX',
  'accY',
  'accZ',
];
target.forEach((key) => {
  const tr = table.appendChild(document.createElement("tr"));
  const th = tr.appendChild(document.createElement("th"));
  th.innerText = key;
  const td = tr.appendChild(document.createElement("td"));
  td.id = key;
});


// chart
const chartTarget = [
  // 'fitError',
  // 'isWalking',
  // 'noiseStatus',
  // 'powerLeft',
  // 'eyeMoveUp',
  // 'eyeMoveDown',
  // 'eyeMoveLeft',
  // 'eyeMoveRight',
  // 'blinkSpeed',
  // 'blinkStrength',
  'roll',
  'pitch',
  'yaw',
  'accX',
  'accY',
  'accZ',
];

const chart = c3.generate({
  bindto: '#chart',
  data: {
    rows: [
      [...chartTarget],
    ],
    axes: {
      'roll': 'y2',
      'pitch': 'y2',
      'yaw': 'y2',
    },
    type: 'spline'
  },
  axis: {
    y: {
    },
    y2: {
      show: true,
      label:{
        text: 'degree',
        position: 'outer-middle',
      },
    },
  },
  subchart: {
    show: true,
  },
  transration: {
    duration: 0,
  },
});

let data = [];
db.ref('/public/meme/hiro-asano/now').on('value', (res) => {
  const row = {};
  res.forEach((item) => {
    document.querySelector(`#${item.key}`).innerText = item.val();
    row[item.key] = item.val();
  });
  data.push(chartTarget.map((k) => row[k]));
  if (data.length > 30) {
    data = data.slice(data.length-30);
  }
  chart.load({
    rows: [
      [...chartTarget],
      ...data,
    ],
  });
});

