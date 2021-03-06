//<?php
/**
 * Commerce
 *
 * Commerce solution
 *
 * @category    plugin
 * @version     0.1.0
 * @author      mnoskov
 * @internal    @events OnWebPageInit,OnManagerPageInit,OnPageNotFound,OnManagerMenuPrerender,OnCacheUpdate
 * @internal    @properties &payment_success_page_id=Page ID for redirect after successfull payment;text; &payment_failed_page_id=Page ID for redirect after payment error;text; &status_id_after_payment=Status ID after payment;text;
 * @internal    @modx_category Commerce
 * @internal    @disabled 1
 * @internal    @installset base
*/

if (!class_exists('Commerce\\Commerce')) {
    require_once MODX_BASE_PATH . 'assets/plugins/commerce/autoload.php';

    $ci = ci();

    $ci->set('modx', function($ci) use ($modx) {
        return $modx;
    });

    $ci->set('commerce', function($ci) use ($modx, $params) {
        return new Commerce\Commerce($modx, $params);
    });

    $ci->set('currency', function($ci) {
        return $ci->commerce->currency;
    });

    $ci->set('cache', function($ci) use ($modx) {
        return Commerce\Cache::getInstance();
    });

    $ci->set('carts', function($ci) use ($modx) {
        return Commerce\CartsManager::getManager($modx);
    });

    $ci->set('db', function($ci) {
        return $ci->modx->db;
    });
}

if (empty($modx->commerce) || isset($modx->commerce) && !($modx->commerce instanceof Commerce\Commerce)) {
    $modx->commerce = $ci->commerce;
}

$e = &$modx->Event;

switch ($e->name) {
    case 'OnWebPageInit': {
        $modx->regClientScript('assets/plugins/commerce/js/commerce.js', [
            'version' => $modx->commerce->getVersion(),
        ]);
        break;
    }

    case 'OnManagerMenuPrerender': {
        $moduleid = $modx->db->getValue($modx->db->select('id', $modx->getFullTablename('site_modules'), "name = 'Commerce'"));
        $url = 'index.php?a=112&id=' . $moduleid;
        $lang = $modx->commerce->getUserLanguage('menu');

        $params['menu'] = array_merge($params['menu'], [
            'commerce' => ['commerce', 'main', '<i class="fa fa-shopping-cart"></i>' . $lang['menu.commerce'], 'javascript:;', $lang['menu.commerce'], 'return false;', 'exec_module', 'main', 0, 90, ''],
            'orders'   => ['orders', 'commerce', '<i class="fa fa-list"></i>' . $lang['menu.orders'], $url . '&route=orders', $lang['menu.orders'], '', 'exec_module', 'main', 0, 10, ''],
            'statuses' => ['statuses', 'commerce', '<i class="fa fa-play-circle"></i>' . $lang['menu.statuses'], $url . '&route=statuses', $lang['menu.statuses'], '', 'exec_module', 'main', 0, 20, ''],
            'currency' => ['currency', 'commerce', '<i class="fa fa-usd"></i>' . $lang['menu.currency'], $url . '&route=currency', $lang['menu.currency'], '', 'exec_module', 'main', 0, 30, ''],
        ]);

        $e->output(serialize($params['menu']));
        break;
    }

     case 'OnPageNotFound': {
        $url = trim(parse_url($_SERVER['REQUEST_URI'], PHP_URL_PATH), '/');

        if (strpos($url, 'commerce') === 0) {
            $modx->commerce->processRoute($url);
        }
        break;
    }

    case 'OnCacheUpdate': {
        ci()->cache->clean();
        break;
    }
}
