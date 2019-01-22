#include "cachednetworkaccessmanagerfactory.h"

#include <QDir>
#include <QStandardPaths>

CachedNetworkAccessManagerFactory::CachedNetworkAccessManagerFactory(const QNetworkProxy& proxy)
    : cache(new QNetworkDiskCache()), proxy(proxy)
{
    QDir cacheDir(
                QStandardPaths::writableLocation(QStandardPaths::CacheLocation)
                + "/http-cache");
    if (!cacheDir.exists() && !cacheDir.mkpath(".")) {
        throw std::runtime_error("Cache directory cannot be created");
    }
    cache->setCacheDirectory(cacheDir.absolutePath());
    cache->setMaximumCacheSize(16777216 /* 16MB */);
}

CachedNetworkAccessManagerFactory::~CachedNetworkAccessManagerFactory()
{
    delete cache;
}

QNetworkAccessManager *CachedNetworkAccessManagerFactory::create(QObject *parent)
{
    auto nam = new QNetworkAccessManager(parent);
    nam->setProxy(proxy);
    nam->setCache(cache);
    return nam;
}

