var express = require('express')
var session = require('express-session')
var bodyParser = require('body-parser');
var mysql = require('mysql2');

const pool = mysql.createPool({
     host: process.env.MYSQL_HOST, 
     user: process.env.MYSQL_USER, 
     password: process.env.MYSQL_PASSWORD,
     database: process.env.MYSQL_DB,
     connectionLimit: 5,
});

const port = 3000

var app = express()

pool.query(`CREATE TABLE IF NOT EXISTS bandiere(
  id INT UNSIGNED AUTO_INCREMENT PRIMARY KEY,
  testo TEXT NOT NULL
);`, function (error, results, fields) {
  if (error) throw error;
});

app.use(bodyParser.json())

app.post('/bandiera', (req, res) => {
    const bandiera = req.body.bandiera
    if (bandiera === undefined) {
      res.status(400).json({"errore":"Il campo 'bandiera' non è stato fornito."})
      return
    }
    
    pool.query("INSERT INTO bandiere(testo) value(?)", [bandiera], function(err, results, fields) {
      if (err !== null) {
        console.error(err)
        res.status(500).json({"errore": "Errore interno del server."})
        return
      }
      
      res.status(200).json({"id": results.insertId})
    });
})

app.get('/bandiera', (req, res) => {
  const id = req.body.id
  if (id === undefined) {
    res.status(400).json({"errore": "Il campo 'id' non è stato fornito."})
    return
  }
  
  pool.query("SELECT testo FROM bandiere WHERE id = ? LIMIT 1", [id], function(err, results, fields) {
    if (err !== null) {
      console.error(err)
      res.status(500).json({"errore": "Errore interno del server."})
      return
    }
    
    if (results.length == 0) {
      res.status(404).json({"errore": "Non ho trovato la bandiera corrispondente al tuo id."})
      return
    }
    
    res.status(200).json({"bandiera": results[0].testo})
  });
})

app.listen(port, () => {
  console.log(`bandiera sta ascoltando sulla porta ${port}`)
})