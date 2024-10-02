# MySQL'in resmi Docker imajını kullanıyoruz
FROM mysql:5.7

# MySQL root kullanıcısının şifresini belirliyoruz
ENV MYSQL_ROOT_PASSWORD=123

# İsteğe bağlı olarak varsayılan bir veritabanı oluşturuyoruz
ENV MYSQL_DATABASE=deid

# İsteğe bağlı olarak özel bir kullanıcı ekliyoruz
ENV MYSQL_USER=raife
ENV MYSQL_PASSWORD=123

# İsteğe bağlı olarak SQL dump dosyalarını kullanarak başlangıç verisi yükleyebilirsiniz
# Eğer SQL dump dosyalarınız varsa, aşağıdaki satırları kullanabilirsiniz:
# COPY ./init.sql /docker-entrypoint-initdb.d/

# MySQL'in çalıştırılması
EXPOSE 3306

CMD ["mysqld"]
