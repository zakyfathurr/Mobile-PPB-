# TUGAS 2
Berikut adalah hierarki widget yang digunakan pada app :

```text
MyApp (StatelessWidget)
 └── MaterialApp
      └── RowColumnPage (StatelessWidget)
           └── Scaffold
                ├── AppBar
                │    └── Text ('My First App')
                └── body: Column
                     ├── Container (⚠️ Redundan)
                     │    └── AspectRatio
                     │         └── Container
                     │              └── Center
                     │                   └── Image.network
                     ├── Container
                     │    └── Text ('What image is that')
                     ├── Container
                     │    └── Row
                     │         ├── Column [Icon(food_bank), Text]
                     │         ├── Column [Icon(landscape), Text]
                     │         └── Column [Icon(people), Text]
                     └── CounterCard (StatefulWidget)
                          └── Container
                               └── Row
                                    ├── Text ('Counter here: X')
                                    └── Container
                                         └── IconButton
```

## List Widget yang digunakan dan fungsinya: 

1. MyApp (StatelessWidget)

Merupakan root widget dari aplikasi Flutter.

Digunakan untuk membangun struktur awal aplikasi.

Karena StatelessWidget, widget ini tidak memiliki state yang berubah selama aplikasi berjalan.

2. MaterialApp

Widget utama untuk aplikasi yang menggunakan Material Design.

Mengatur konfigurasi aplikasi seperti:

- theme

- title

- routing/navigation

- home page

Biasanya menjadi pembungkus utama seluruh halaman aplikasi.

3. RowColumnPage (StatelessWidget)

Widget halaman utama aplikasi.

Mengatur layout halaman menggunakan widget lain seperti Scaffold, Column, Row, dll.

Stateless karena tidak menyimpan state yang berubah.

4. Scaffold

Menyediakan struktur dasar layout halaman Material Design.

Memiliki beberapa bagian utama seperti:

- AppBar
- body
- floatingActionButton
- drawer

Digunakan sebagai kerangka halaman.

5. AppBar

Widget untuk membuat header atau bar bagian atas aplikasi.

Biasanya berisi:

- Judul

- Icon

- Action button

6. Text

Digunakan untuk menampilkan teks pada layar.

Contoh:

- 'My First App'

- 'What image is that'

- 'Counter here: X'

7. Column

Widget layout yang menyusun child widget secara vertikal (atas ke bawah).

Contoh penggunaan:

- Menyusun gambar

- Menyusun teks

- Menyusun row icon

8. Row

Widget layout yang menyusun child widget secara horizontal (kiri ke kanan).

Contoh penggunaan:

Menyusun beberapa icon dan text secara sejajar.

9. Container

Widget serbaguna untuk:

- memberi padding

- memberi margin

- memberi warna background

- mengatur ukuran

- membungkus widget lain

⚠️ Pada soal disebut Container redundan karena sebenarnya tidak diperlukan.

10. AspectRatio

Digunakan untuk menjaga rasio lebar dan tinggi widget.

Contoh:

gambar tetap memiliki rasio tertentu walaupun ukuran layar berubah.

11. Center

Widget untuk memposisikan child tepat di tengah parent widget.

12. Image.network

Widget untuk menampilkan gambar dari URL internet.

Contoh:

Image.network("https://example.com/image.jpg")
13. Icon

Widget untuk menampilkan icon dari Material Icons.

Contoh icon:

- Icons.food_bank

- Icons.landscape

- Icons.people

14. CounterCard (StatefulWidget)

Widget yang memiliki state yang dapat berubah.

Digunakan untuk membuat counter yang bisa bertambah saat tombol ditekan.

Karena menggunakan StatefulWidget, nilai counter bisa berubah selama aplikasi berjalan.

15. IconButton

Widget tombol berbentuk icon yang bisa ditekan.

Biasanya memiliki fungsi onPressed.

Contoh:

IconButton(
  icon: Icon(Icons.add),
  onPressed: () {}
)
