# Frontend için Dockerfile

# Nginx bazlı bir imaj kullanıyoruz
FROM nginx:alpine

# Nginx'in varsayılan ayar dosyasını silip kendi ayarlarımızı ekliyoruz
COPY frontend/nginx.conf /etc/nginx/nginx.conf

# Statik dosyaları Nginx sunucusuna kopyala
COPY . /usr/share/nginx/html

# Nginx'i başlat
CMD ["nginx", "-g", "daemon off;"]
