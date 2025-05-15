# HOLO (Horizon-Oriented Laser Output)

## Introduction to the problem and the solution
Saat ini, sistem penunjukan arah menjadi bagian yang penting dalam berbagai bidang, seperti astronomi, sistem kendali, hingga teknologi informasi. Sistem ini biasanya memanfaatkan sistem koordinat Azimuth (horizontal) dan Altitude (vertikal) sebagai acuan untuk menunjuk arah secara akurat. Akan tetapi, penunjukan arah secara manual dengan tenaga manusia tidak efisien dan rawan terhadap human error, dimana pennunjukan arah seringkali tidak akurat.  

Sebagai solusi dari masalah yang telah disebutkan, kami mengimplementasikan Arduino untuk melakukan otomasi proses penunjukan arah. Terdapat dua Arduino yang kami gunakan, yaitu Arduino master yang berfungsi untuk menerima input pengguna dan Arduino slave yang berfungsi untuk menggerakkan servo. Kami menggunakan keypad untuk menerima input derajat azimuth dan altitude dari pengguna. Nilai input dari pengguna ditampilkan dengan serial display.

Data input dari pengguna dikirimkan dari master ke slave untuk mengendalikan servo yang terhubung dengan PWM. Kalibrasi dilakukan untuk memastikan sudut perputaran servo sesuai dengan input dari pengguna. Kami juga mengintegrasikan reset button untuk mengembalikan servo ke posisi awal. Implementasi seluruh fungsionalitas ini diharapkan dapat menghasilkan sistem penunjukan arah yang akurat dan efisien, serta minim intervensi.

## Hardware design and implementation details
Dalam membuat sistem penunjukan arah “HOLO,” dibutuhkan sejumlah komponen yang perlu diselaraskan. Terdapat 2 buah Arduino yang digunakan dimana satu Arduino berperan sebagai master dan Arduino lainnya berperan sebagai slave. Pada Arduino master, terdapat sebuah keypad yang berfungsi untuk menetima input derajat dari pengguna. Keypad tersebut sekaligus berfungsi untuk mengganti mode (azimuth/altitude) dan men-trigger pergerakan servo. Input tersebut ditampilkan dengan serial display MAX7219 yang dihubungkan dengan protokol Serial Peripheral Interface (SPI) dengan format “Azm/Alt (spasi) Derajat.”

Pada Arduino slave, terdapat 2 servo 180° untuk azimuth dan altitude, serta reset button untuk mengembalikan posisi servo. Untuk menghubungkan kedua Arduino, digunakan protokol Inter-Integrated Circuit (I2C). Arduino master akan mengirimkan input pengguna kepada Arduino slave setiap pengguna menekan tombol ❉ atau #. Arduino slave kemudian mengolah input pengguna untuk menggerakkan servo sesuai derajat yang diinput oleh pengguna.

## Software implementation details

## Test results and performance evaluation

## Conclusion and future work
