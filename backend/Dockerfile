# Backend için Dockerfile

# Python 3.9-slim baz imajını kullanıyoruz. Bu imaj, hafif bir Python sürümüdür.
FROM python:3.9-slim

# Uygulamanın çalışacağı dizini /app olarak ayarlıyoruz.
WORKDIR /app

# Dockerize aracını yükleme:
# Dockerize, MySQL gibi servislerin tam olarak başlamasını beklemek için kullanılır.
# Aşağıdaki komutlar ile dockerize aracını indiriyoruz ve kuruyoruz.
RUN apt-get update && apt-get install -y wget tar \
    && wget https://github.com/jwilder/dockerize/releases/download/v0.6.1/dockerize-linux-amd64-v0.6.1.tar.gz \
    && tar -C /usr/local/bin -xzvf dockerize-linux-amd64-v0.6.1.tar.gz \
    && chmod +x /usr/local/bin/dockerize && rm dockerize-linux-amd64-v0.6.1.tar.gz

#############################  DOCKERİZE KOMUTU AÇIKLAMASI  ##############################
# 1. RUN Komutu:
#     RUN, Dockerfile içinde bir Docker imajı oluşturulurken, belirtilen komutların çalıştırılmasını sağlar.
#     Dockerfile'daki her RUN komutu, yeni bir imaj katmanı oluşturur. Yani, bu adımda verilen komutlar imajın inşa sürecinde çalıştırılır ve imaja kaydedilir.

# 2. dnf install -y wget:
#     dnf: Fedora ve Red Hat tabanlı sistemlerde kullanılan paket yöneticisidir. Debian tabanlı sistemlerde apt-get kullanılmasına karşın, Fedora'da dnf kullanılır.
#     install: Paket yöneticisine, belirtilen paketi yüklemesini söyleyen komuttur. Burada wget paketini yüklüyoruz.
#     -y (yes): Bu bayrak, dnf install komutunun onay gerektiren adımlarında otomatik olarak "evet" (yes) demesini sağlar. Kullanıcı müdahalesi olmadan işlemin devam etmesi için kullanılır. Bu, Docker imajı oluşturulurken işlemi kesintisiz hale getirir.
#     wget: Bu paket, dosyaları internetten indirmek için kullanılan bir araçtır. Burada, Dockerize aracı tar.gz formatında indirileceği için wget kullanılıyor.

# 3. wget https://github.com/jwilder/dockerize/releases/download/v0.6.1/dockerize-linux-amd64-v0.6.1.tar.gz:
#     wget: İnternetten dosya indirmeye yarayan bir araçtır.
#     https://github.com/.../dockerize-linux-amd64-v0.6.1.tar.gz: Bu URL, Dockerize aracının GitHub üzerindeki tar.gz formatındaki sıkıştırılmış dosyasının indirilmesini sağlar. Bu dosya, Dockerize'ın ilgili sürümünü içerir.

# 4. tar -C /usr/local/bin -xzvf dockerize-linux-amd64-v0.6.1.tar.gz:
#     tar: Sıkıştırılmış dosyaları açmak ve çıkarmak için kullanılan bir komuttur.
#     -C /usr/local/bin: Bu bayrak, çıkarılan dosyaların nereye kopyalanacağını belirtir. Burada, Dockerize dosyasını /usr/local/bin dizinine çıkarmak istiyoruz. /usr/local/bin dizini, genellikle sistem genelinde yürütülebilir dosyaların bulunduğu yerdir.

#     Diğer tar bayrakları:
    
#     -x: Sıkıştırılmış dosyayı extract (çıkarmak) anlamına gelir. Yani tar.gz dosyasını açar.
#     -z: Dosyanın gzip formatında sıkıştırıldığını belirtir (tar.gz formatı).
#     -v: Verbose modu aktif eder. Çıkarma işlemi sırasında hangi dosyaların çıkarıldığını terminale yazar. Bu, işlemin izlenmesini sağlar.
#     -f dockerize-linux-amd64-v0.6.1.tar.gz: Hangi dosyanın çıkarılacağını belirtir. Burada, çıkarmak istediğimiz dosya dockerize-linux-amd64-v0.6.1.tar.gz dosyasıdır.

# 5. chmod +x /usr/local/bin/dockerize:
#     chmod: Dosya izinlerini değiştiren bir komuttur.
#     +x: Dosyaya yürütülebilir (executable) izin verir. Bu, dosyanın bir program gibi çalıştırılabilmesi için gereklidir.
#     /usr/local/bin/dockerize: Bu, Dockerize binary dosyasının konumunu belirtir. Tar komutu ile bu dizine çıkarılmış dosyanın yürütülebilir olması için izin veriyoruz. Bu sayede, dockerize komutu terminalden çalıştırılabilir hale gelir.

# 6. rm dockerize-linux-amd64-v0.6.1.tar.gz:
#     rm: Dosya silme komutudur.
#     dockerize-linux-amd64-v0.6.1.tar.gz: Daha önce indirdiğimiz tar.gz dosyasını sileriz, çünkü artık bu dosyaya ihtiyacımız kalmamıştır. Tar dosyasını çıkarıp gerekli binary dosyasını aldıktan sonra temizleme işlemi yapıyoruz. Bu, Docker imajının gereksiz dosyalarla şişmesini önler.
############################################################################################################

# Gereksinim dosyalarını kopyala
COPY backend/requirements.txt requirements.txt

# Bağımlılıkları yükle
RUN pip install --no-cache-dir -r requirements.txt

# Uygulama dosyalarını kopyala
COPY . .

# Ortam değişkenlerini ayarla
ENV FLASK_APP=app.py

# MySQL servisi başlamadan önce bir süre bekleme ihtiyacı olabilir.
# Buna yardımcı olacak bir bekleme scripti kullanabiliriz, bu opsiyoneldir.

# Flask uygulamasını çalıştır
# CMD ["flask", "run", "--host=0.0.0.0", "--port=5000"]

######### MySQL servisi başlamadan önce bekleme:(dockerize)######## 
# 'dockerize' aracını kullanarak MySQL'in 3306 portunda hazır olup olmadığını bekliyoruz.
# Bu, MySQL gibi bağımlı servislerin başlama süresine göre uygulamanızın hata almadan çalışmasını sağlar.
CMD ["dockerize", "-wait", "tcp://mysql:3306", "-timeout", "30s", "flask", "run", "--host=0.0.0.0", "--port=5000"]

# dockerize ile MySQL servisinin başlamasını beklemek:
# CMD komutunda, dockerize aracını kullanarak tcp://mysql:3306 portunun açılmasını bekliyoruz.
# -timeout 30s ifadesi, 30 saniye boyunca MySQL'in başlamasını bekleyeceğimizi belirtiyor. Eğer bu sürede MySQL başlarsa Flask uygulaması çalıştırılacaktır. Eğer bu süre içinde başlamazsa, uygulama hata verecektir.
# Bu yöntem, servisin başlamasını dinamik bir şekilde beklemek için idealdir.

#########################################################################################

#########MySQL servisi başlamadan önce sabit bir süre bekleme:(sleep)#######
# 'sleep' komutu ile sabit bir süre (örneğin 10 saniye) bekliyoruz.
# Bu süre zarfında MySQL'in başlamış olacağını varsayıyoruz. 
# Ancak bu yöntem dinamik değildir, ve her durumda güvenilir olmayabilir.
# CMD ["sh", "-c", "sleep 10 && flask run --host=0.0.0.0 --port=5000"]

# Notlar:
# 1. 'sleep 10' ifadesi, 10 saniye boyunca beklemeyi sağlar. Eğer MySQL gibi bağımlı servislerin tam olarak başlama süresini
#    biliyorsanız bu yöntemi kullanabilirsiniz.
# 2. '&&' ile komutları zincirliyoruz. Sleep tamamlandıktan sonra Flask uygulaması başlatılacaktır.
# 3. Bu yöntem statik bir bekleme süresi tanımladığı için, servis daha uzun sürede başlarsa uygulamanız hata verebilir.

##################################### DOCKER İMAGE OLUŞTURMA ########################################

# Direk olarak Dockerfile üzerinden image build edilmesi ve Dockerfile üzerinden image çalıştırılması komutları:
    # docker build -t image-name . komutunun işlevini açıklayalım:

    #     Komutun Parçaları:
    #     docker build:
        
    #     Bu komut, Dockerfile'ı kullanarak bir Docker imajı oluşturur.
    #     Docker, belirtilen dizindeki Dockerfile ve diğer gerekli dosyaları kullanarak imaj oluşturur.

    #     -t image-name:
        
    #     -t bayrağı, imaj için bir etiket (tag) belirlemenizi sağlar.
    #     image-name, oluşturulan Docker imajına vereceğiniz isimdir. İmajınıza kolayca tanınabilir bir isim vermek için kullanılır.
    #     Örneğin, -t my-app kullanırsanız, imajınız "my-app" olarak adlandırılır. Dilerseniz versiyon bilgisi ekleyebilirsiniz: -t my-app:v1.

    #     . (Nokta):
        
    #     Bu, Docker’ın build context'ini belirler.
    #     . (nokta) bulunduğunuz dizini ifade eder. Yani Docker bu dizindeki Dockerfile ve gerekli dosyaları kullanarak imaj oluşturacaktır.
    #     Başka bir dizinde Dockerfile ve kaynaklarınız varsa, o dizinin yolunu buraya yazabilirsiniz (örneğin, docker build -t image-name /path/to/directory).

################################## DOCKER İMAGE ÇALIŞTIRMA ####################################

# docker run -it image-name /bin/bash komutunun işlevini ve hangi durumlarda kullanıldığını adım adım açıklayalım:

#     Komutun Parçaları:
#     docker run:
    
#     docker run komutu, bir Docker imajını çalıştırır ve bu imajdan bir konteyner başlatır.
#     Yani, bu komut ile Docker imajını bir konteyner içinde çalıştırmış olursunuz.

#     -it:
    
#     -i: Etkileşimli mod anlamına gelir. Bu, komut satırına (stdin) giriş yapmanıza olanak tanır, yani komut satırında girdiler verebilirsiniz. -i bayrağı olmadan, konteyner başlatıldığında komut satırından veri girişi yapamazsınız.
#     -t: Tersan terminali (pseudo-TTY) oluşturur. Bu, komut satırında bir terminal ortamı oluşturur ve kullanıcıya normal bir terminal gibi görünür.
#     -it birlikte kullanıldığında, konteyneri etkileşimli modda başlatır ve bir terminal ortamı sağlar. Böylece, konteyner içinde komutlar çalıştırabilir, dosya sistemi ile etkileşime girebilir ve konteynerin içinde neler olduğunu görebilirsiniz.

#     image-name:
    
#     Bu, çalıştırmak istediğiniz Docker imajının adıdır. Önceden oluşturduğunuz veya indirdiğiniz bir imajı burada kullanırsınız.
#     Örneğin, eğer bir imajı docker build -t my-app . ile oluşturduysanız, burada my-app olarak çağırırsınız.

#     /bin/bash:
    
#     Bu, konteyner içinde çalıştırmak istediğiniz komutu belirtir.
#     /bin/bash komutu, konteyner içinde bir bash kabuğu başlatır. Bu sayede, sanki konteynerde bir terminaldeymiş gibi komutlar verebilir ve sistemle etkileşime geçebilirsiniz.
#     Eğer imajınızda bash yüklü değilse, başka bir kabuk kullanabilirsiniz (örneğin, sh).
