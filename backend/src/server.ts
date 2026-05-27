import express from 'express';

const app = express();

app.get('/', (req, res) => {
  res.send('Backend LUMI funcionando');
});

app.listen(3000, () => {
  console.log('Servidor corriendo en puerto 3000');
});