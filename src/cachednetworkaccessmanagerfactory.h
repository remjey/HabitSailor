#ifndef CACHEDNETWORKACCESSMANAGERFACTORY_H
#define CACHEDNETWORKACCESSMANAGERFACTORY_H

#include <QNetworkDiskCache>
#include <QNetworkProxy>
#include <QQmlNetworkAccessManagerFactory>
#include <QNetworkAccessManager>

class CachedNetworkAccessManagerFactory : public QQmlNetworkAccessManagerFactory
{
public:
    CachedNetworkAccessManagerFactory(const QNetworkProxy& proxy);
    ~CachedNetworkAccessManagerFactory();

    virtual QNetworkAccessManager *create(QObject *parent);

protected:
    QNetworkDiskCache *cache;
    const QNetworkProxy proxy;
};

#endif // CACHEDNETWORKACCESSMANAGERFACTORY_H
