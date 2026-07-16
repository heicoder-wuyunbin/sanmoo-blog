-- MySQL dump 10.13  Distrib 8.4.5, for macos15.2 (arm64)
--
-- Host: localhost    Database: sanmoo_blog
-- ------------------------------------------------------
-- Server version	8.4.5

/*!40101 SET @OLD_CHARACTER_SET_CLIENT=@@CHARACTER_SET_CLIENT */;
/*!40101 SET @OLD_CHARACTER_SET_RESULTS=@@CHARACTER_SET_RESULTS */;
/*!40101 SET @OLD_COLLATION_CONNECTION=@@COLLATION_CONNECTION */;
/*!50503 SET NAMES utf8mb4 */;
/*!40103 SET @OLD_TIME_ZONE=@@TIME_ZONE */;
/*!40103 SET TIME_ZONE='+00:00' */;
/*!40014 SET @OLD_UNIQUE_CHECKS=@@UNIQUE_CHECKS, UNIQUE_CHECKS=0 */;
/*!40014 SET @OLD_FOREIGN_KEY_CHECKS=@@FOREIGN_KEY_CHECKS, FOREIGN_KEY_CHECKS=0 */;
/*!40101 SET @OLD_SQL_MODE=@@SQL_MODE, SQL_MODE='NO_AUTO_VALUE_ON_ZERO' */;
/*!40111 SET @OLD_SQL_NOTES=@@SQL_NOTES, SQL_NOTES=0 */;

--
-- Table structure for table `t_access_log`
--

DROP TABLE IF EXISTS `t_access_log`;
/*!40101 SET @saved_cs_client     = @@character_set_client */;
/*!50503 SET character_set_client = utf8mb4 */;
CREATE TABLE `t_access_log` (
  `id` bigint unsigned NOT NULL AUTO_INCREMENT COMMENT 'id',
  `trace_id` varchar(64) CHARACTER SET utf8mb4 COLLATE utf8mb4_unicode_ci NOT NULL DEFAULT '' COMMENT '请求追踪ID',
  `request_method` varchar(12) CHARACTER SET utf8mb4 COLLATE utf8mb4_unicode_ci NOT NULL DEFAULT '' COMMENT '请求方法',
  `request_url` varchar(500) CHARACTER SET utf8mb4 COLLATE utf8mb4_unicode_ci NOT NULL COMMENT '请求URL',
  `request_path` varchar(300) CHARACTER SET utf8mb4 COLLATE utf8mb4_unicode_ci NOT NULL DEFAULT '' COMMENT '请求路径',
  `request_query` text CHARACTER SET utf8mb4 COLLATE utf8mb4_unicode_ci COMMENT '请求Query参数',
  `request_params` text CHARACTER SET utf8mb4 COLLATE utf8mb4_unicode_ci COMMENT '请求参数',
  `request_body` mediumtext CHARACTER SET utf8mb4 COLLATE utf8mb4_unicode_ci COMMENT '请求体',
  `visitor_user_id` bigint unsigned NOT NULL DEFAULT '0' COMMENT '访问用户ID（未登录为0）',
  `visitor_name` varchar(100) CHARACTER SET utf8mb4 COLLATE utf8mb4_unicode_ci NOT NULL DEFAULT '游客' COMMENT '访问用户名称',
  `ip_address` varbinary(16) NOT NULL DEFAULT '\0\0' COMMENT 'IP地址',
  `request_time` datetime NOT NULL DEFAULT CURRENT_TIMESTAMP COMMENT '请求时间',
  `response_time` int NOT NULL DEFAULT '0' COMMENT '响应时间（毫秒）',
  `response_status` int NOT NULL DEFAULT '0' COMMENT '响应状态码',
  `response_body` mediumtext CHARACTER SET utf8mb4 COLLATE utf8mb4_unicode_ci COMMENT '响应内容',
  `user_agent` varchar(500) CHARACTER SET utf8mb4 COLLATE utf8mb4_unicode_ci NOT NULL DEFAULT '' COMMENT '用户代理',
  `request_source` varchar(100) CHARACTER SET utf8mb4 COLLATE utf8mb4_unicode_ci NOT NULL DEFAULT '' COMMENT '请求来源（如：iPhone微信、Chrome浏览器等）',
  `is_error` tinyint(1) NOT NULL DEFAULT '0' COMMENT '是否错误',
  `error_id` bigint unsigned DEFAULT NULL COMMENT '错误日志ID',
  `create_time` datetime NOT NULL DEFAULT CURRENT_TIMESTAMP COMMENT '创建时间',
  PRIMARY KEY (`id`) USING BTREE,
  KEY `idx_request_time` (`request_time`) USING BTREE,
  KEY `idx_ip_address` (`ip_address`) USING BTREE,
  KEY `idx_response_status` (`response_status`) USING BTREE,
  KEY `idx_request_source` (`request_source`) USING BTREE,
  KEY `idx_trace_id` (`trace_id`) USING BTREE,
  KEY `idx_is_error` (`is_error`) USING BTREE,
  KEY `idx_error_id` (`error_id`) USING BTREE
) ENGINE=InnoDB AUTO_INCREMENT=7962 DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci ROW_FORMAT=DYNAMIC COMMENT='用户访问日志表';
/*!40101 SET character_set_client = @saved_cs_client */;

--
-- Table structure for table `t_article`
--

DROP TABLE IF EXISTS `t_article`;
/*!40101 SET @saved_cs_client     = @@character_set_client */;
/*!50503 SET character_set_client = utf8mb4 */;
CREATE TABLE `t_article` (
  `id` bigint unsigned NOT NULL AUTO_INCREMENT COMMENT '文章id',
  `title` varchar(200) CHARACTER SET utf8mb4 COLLATE utf8mb4_unicode_ci NOT NULL DEFAULT '' COMMENT '文章标题',
  `slug` varchar(100) CHARACTER SET utf8mb4 COLLATE utf8mb4_unicode_ci DEFAULT NULL COMMENT '文章 URL 别名（SEO 友好）',
  `title_image` varchar(200) CHARACTER SET utf8mb4 COLLATE utf8mb4_unicode_ci DEFAULT '' COMMENT '文章题图',
  `description` varchar(160) CHARACTER SET utf8mb4 COLLATE utf8mb4_unicode_ci NOT NULL DEFAULT '' COMMENT '文章描述',
  `create_time` datetime NOT NULL DEFAULT CURRENT_TIMESTAMP COMMENT '创建时间',
  `update_time` datetime NOT NULL DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP COMMENT '最后一次更新时间',
  `read_num` int unsigned NOT NULL DEFAULT '1' COMMENT '被阅读次数',
  `share_num` int DEFAULT '0' COMMENT '分享次数',
  `is_top` tinyint(1) NOT NULL DEFAULT '0' COMMENT '是否置顶：0：否 1：是',
  `is_published` tinyint(1) NOT NULL DEFAULT '1' COMMENT '是否发布：0：否 1：是',
  `publish_time` datetime DEFAULT NULL COMMENT 'å®šæ—¶å‘å¸ƒæ—¶é—´',
  `created_by` varchar(60) CHARACTER SET utf8mb4 COLLATE utf8mb4_unicode_ci NOT NULL DEFAULT '' COMMENT '创建人',
  `updated_by` varchar(60) CHARACTER SET utf8mb4 COLLATE utf8mb4_unicode_ci NOT NULL DEFAULT '' COMMENT '更新人',
  `like_num` int NOT NULL DEFAULT '0' COMMENT 'ç‚¹èµžæ•°',
  PRIMARY KEY (`id`) USING BTREE,
  UNIQUE KEY `uk_slug` (`slug`),
  KEY `idx_create_time` (`create_time`) USING BTREE,
  KEY `idx_is_top` (`is_top`) USING BTREE,
  KEY `idx_is_published` (`is_published`) USING BTREE,
  KEY `idx_top_published_time` (`is_top`,`is_published`,`create_time`) USING BTREE
) ENGINE=InnoDB AUTO_INCREMENT=60 DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci ROW_FORMAT=DYNAMIC COMMENT='文章表';
/*!40101 SET character_set_client = @saved_cs_client */;

--
-- Table structure for table `t_article_category_rel`
--

DROP TABLE IF EXISTS `t_article_category_rel`;
/*!40101 SET @saved_cs_client     = @@character_set_client */;
/*!50503 SET character_set_client = utf8mb4 */;
CREATE TABLE `t_article_category_rel` (
  `id` bigint unsigned NOT NULL AUTO_INCREMENT COMMENT 'id',
  `article_id` bigint unsigned NOT NULL COMMENT '文章id',
  `category_id` bigint unsigned NOT NULL COMMENT '分类id',
  `create_time` datetime NOT NULL DEFAULT CURRENT_TIMESTAMP COMMENT '创建时间',
  `update_time` datetime NOT NULL DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP COMMENT '最后一次更新时间',
  `created_by` varchar(60) CHARACTER SET utf8mb4 COLLATE utf8mb4_unicode_ci NOT NULL DEFAULT '' COMMENT '创建人',
  `updated_by` varchar(60) CHARACTER SET utf8mb4 COLLATE utf8mb4_unicode_ci NOT NULL DEFAULT '' COMMENT '更新人',
  PRIMARY KEY (`id`) USING BTREE,
  UNIQUE KEY `uk_article_category` (`article_id`,`category_id`),
  KEY `idx_category_id` (`category_id`) USING BTREE
) ENGINE=InnoDB AUTO_INCREMENT=133 DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci ROW_FORMAT=DYNAMIC COMMENT='文章所属分类映射表';
/*!40101 SET character_set_client = @saved_cs_client */;

--
-- Table structure for table `t_article_content`
--

DROP TABLE IF EXISTS `t_article_content`;
/*!40101 SET @saved_cs_client     = @@character_set_client */;
/*!50503 SET character_set_client = utf8mb4 */;
CREATE TABLE `t_article_content` (
  `id` bigint unsigned NOT NULL AUTO_INCREMENT COMMENT '文章内容id',
  `article_id` bigint unsigned NOT NULL COMMENT '文章id',
  `content` text CHARACTER SET utf8mb4 COLLATE utf8mb4_unicode_ci COMMENT '正文内容',
  `create_time` datetime NOT NULL DEFAULT CURRENT_TIMESTAMP COMMENT '创建时间',
  `update_time` datetime NOT NULL DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP COMMENT '最后一次更新时间',
  `created_by` varchar(60) CHARACTER SET utf8mb4 COLLATE utf8mb4_unicode_ci NOT NULL DEFAULT '' COMMENT '创建人',
  `updated_by` varchar(60) CHARACTER SET utf8mb4 COLLATE utf8mb4_unicode_ci NOT NULL DEFAULT '' COMMENT '更新人',
  PRIMARY KEY (`id`) USING BTREE,
  UNIQUE KEY `uk_article_id` (`article_id`) USING BTREE,
  CONSTRAINT `fk_article_content_article` FOREIGN KEY (`article_id`) REFERENCES `t_article` (`id`) ON DELETE CASCADE ON UPDATE CASCADE
) ENGINE=InnoDB AUTO_INCREMENT=60 DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci ROW_FORMAT=DYNAMIC COMMENT='文章内容表';
/*!40101 SET character_set_client = @saved_cs_client */;

--
-- Table structure for table `t_article_tag_rel`
--

DROP TABLE IF EXISTS `t_article_tag_rel`;
/*!40101 SET @saved_cs_client     = @@character_set_client */;
/*!50503 SET character_set_client = utf8mb4 */;
CREATE TABLE `t_article_tag_rel` (
  `id` bigint unsigned NOT NULL AUTO_INCREMENT COMMENT 'id',
  `article_id` bigint unsigned NOT NULL COMMENT '文章id',
  `tag_id` bigint unsigned NOT NULL COMMENT '标签id',
  `create_time` datetime NOT NULL DEFAULT CURRENT_TIMESTAMP COMMENT '创建时间',
  `update_time` datetime NOT NULL DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP COMMENT '最后一次更新时间',
  `created_by` varchar(60) CHARACTER SET utf8mb4 COLLATE utf8mb4_unicode_ci NOT NULL DEFAULT '' COMMENT '创建人',
  `updated_by` varchar(60) CHARACTER SET utf8mb4 COLLATE utf8mb4_unicode_ci NOT NULL DEFAULT '' COMMENT '更新人',
  PRIMARY KEY (`id`) USING BTREE,
  UNIQUE KEY `uk_article_tag` (`article_id`,`tag_id`) USING BTREE,
  KEY `idx_article_id` (`article_id`) USING BTREE,
  KEY `idx_tag_id` (`tag_id`) USING BTREE
) ENGINE=InnoDB AUTO_INCREMENT=193 DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci ROW_FORMAT=DYNAMIC COMMENT='文章对应标签映射表';
/*!40101 SET character_set_client = @saved_cs_client */;

--
-- Table structure for table `t_article_topic_rel`
--

DROP TABLE IF EXISTS `t_article_topic_rel`;
/*!40101 SET @saved_cs_client     = @@character_set_client */;
/*!50503 SET character_set_client = utf8mb4 */;
CREATE TABLE `t_article_topic_rel` (
  `id` bigint unsigned NOT NULL AUTO_INCREMENT COMMENT 'id',
  `article_id` bigint unsigned NOT NULL COMMENT '文章id',
  `topic_id` bigint unsigned NOT NULL COMMENT '专题id',
  `sort_order` int NOT NULL DEFAULT '0' COMMENT '排序顺序',
  `create_time` datetime NOT NULL DEFAULT CURRENT_TIMESTAMP COMMENT '创建时间',
  `update_time` datetime NOT NULL DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP COMMENT '最后一次更新时间',
  `created_by` varchar(60) CHARACTER SET utf8mb4 COLLATE utf8mb4_unicode_ci NOT NULL DEFAULT '' COMMENT '创建人',
  `updated_by` varchar(60) CHARACTER SET utf8mb4 COLLATE utf8mb4_unicode_ci NOT NULL DEFAULT '' COMMENT '更新人',
  PRIMARY KEY (`id`) USING BTREE,
  UNIQUE KEY `uk_article_topic` (`article_id`,`topic_id`) USING BTREE,
  KEY `idx_article_id` (`article_id`) USING BTREE,
  KEY `idx_topic_id` (`topic_id`) USING BTREE,
  KEY `idx_sort_order` (`sort_order`) USING BTREE,
  CONSTRAINT `fk_article_topic_article` FOREIGN KEY (`article_id`) REFERENCES `t_article` (`id`) ON DELETE CASCADE ON UPDATE CASCADE,
  CONSTRAINT `fk_article_topic_topic` FOREIGN KEY (`topic_id`) REFERENCES `t_topic` (`id`) ON DELETE CASCADE ON UPDATE CASCADE
) ENGINE=InnoDB AUTO_INCREMENT=116 DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci ROW_FORMAT=DYNAMIC COMMENT='文章-专题关联表';
/*!40101 SET character_set_client = @saved_cs_client */;

--
-- Table structure for table `t_blog_brand_config`
--

DROP TABLE IF EXISTS `t_blog_brand_config`;
/*!40101 SET @saved_cs_client     = @@character_set_client */;
/*!50503 SET character_set_client = utf8mb4 */;
CREATE TABLE `t_blog_brand_config` (
  `id` tinyint unsigned NOT NULL DEFAULT '1' COMMENT '主键，固定为1',
  `blog_name` varchar(60) COLLATE utf8mb4_unicode_ci NOT NULL DEFAULT '' COMMENT '博客名称',
  `author` varchar(60) COLLATE utf8mb4_unicode_ci NOT NULL DEFAULT '' COMMENT '作者名',
  `introduction` varchar(200) COLLATE utf8mb4_unicode_ci NOT NULL DEFAULT '' COMMENT '介绍语',
  `avatar` varchar(160) COLLATE utf8mb4_unicode_ci NOT NULL DEFAULT '' COMMENT '作者头像',
  `site_url` varchar(200) COLLATE utf8mb4_unicode_ci NOT NULL DEFAULT '' COMMENT '站点地址',
  `rss_enabled` tinyint(1) NOT NULL DEFAULT '1' COMMENT 'RSS开关',
  `config_version` int unsigned NOT NULL DEFAULT '1' COMMENT '配置版本号',
  `create_time` datetime NOT NULL DEFAULT CURRENT_TIMESTAMP COMMENT '创建时间',
  `update_time` datetime NOT NULL DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP COMMENT '更新时间',
  `created_by` varchar(60) COLLATE utf8mb4_unicode_ci NOT NULL DEFAULT '' COMMENT '创建人',
  `updated_by` varchar(60) COLLATE utf8mb4_unicode_ci NOT NULL DEFAULT '' COMMENT '更新人',
  PRIMARY KEY (`id`),
  CONSTRAINT `chk_brand_single_row` CHECK ((`id` = 1))
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci COMMENT='博客站点品牌配置表';
/*!40101 SET character_set_client = @saved_cs_client */;

--
-- Table structure for table `t_blog_channel_config`
--

DROP TABLE IF EXISTS `t_blog_channel_config`;
/*!40101 SET @saved_cs_client     = @@character_set_client */;
/*!50503 SET character_set_client = utf8mb4 */;
CREATE TABLE `t_blog_channel_config` (
  `id` tinyint unsigned NOT NULL DEFAULT '1' COMMENT '主键，固定为1',
  `github_home` varchar(120) COLLATE utf8mb4_unicode_ci NOT NULL DEFAULT '' COMMENT 'GitHub主页',
  `csdn_home` varchar(120) COLLATE utf8mb4_unicode_ci NOT NULL DEFAULT '' COMMENT 'CSDN主页',
  `gitee_home` varchar(120) COLLATE utf8mb4_unicode_ci NOT NULL DEFAULT '' COMMENT 'Gitee主页',
  `zhihu_home` varchar(120) COLLATE utf8mb4_unicode_ci NOT NULL DEFAULT '' COMMENT '知乎主页',
  `github_show` tinyint(1) NOT NULL DEFAULT '1' COMMENT '是否显示GitHub',
  `csdn_show` tinyint(1) NOT NULL DEFAULT '1' COMMENT '是否显示CSDN',
  `gitee_show` tinyint(1) NOT NULL DEFAULT '1' COMMENT '是否显示Gitee',
  `zhihu_show` tinyint(1) NOT NULL DEFAULT '1' COMMENT '是否显示知乎',
  `web_enabled` tinyint(1) NOT NULL DEFAULT '1' COMMENT 'Web渠道启用',
  `mp_enabled` tinyint(1) NOT NULL DEFAULT '1' COMMENT '小程序渠道启用',
  `config_version` int unsigned NOT NULL DEFAULT '1' COMMENT '配置版本号',
  `create_time` datetime NOT NULL DEFAULT CURRENT_TIMESTAMP COMMENT '创建时间',
  `update_time` datetime NOT NULL DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP COMMENT '更新时间',
  `created_by` varchar(60) COLLATE utf8mb4_unicode_ci NOT NULL DEFAULT '' COMMENT '创建人',
  `updated_by` varchar(60) COLLATE utf8mb4_unicode_ci NOT NULL DEFAULT '' COMMENT '更新人',
  PRIMARY KEY (`id`),
  CONSTRAINT `chk_channel_single_row` CHECK ((`id` = 1))
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci COMMENT='博客渠道配置表';
/*!40101 SET character_set_client = @saved_cs_client */;

--
-- Table structure for table `t_blog_compliance_config`
--

DROP TABLE IF EXISTS `t_blog_compliance_config`;
/*!40101 SET @saved_cs_client     = @@character_set_client */;
/*!50503 SET character_set_client = utf8mb4 */;
CREATE TABLE `t_blog_compliance_config` (
  `id` tinyint unsigned NOT NULL DEFAULT '1' COMMENT '主键，固定为1',
  `privacy_policy` text COLLATE utf8mb4_unicode_ci COMMENT '隐私政策内容',
  `filing_info` varchar(500) COLLATE utf8mb4_unicode_ci NOT NULL DEFAULT '' COMMENT '备案信息（JSON格式：{"icpCode":"","filingUrl":"","recordType":"个人"}）',
  `contact_info` varchar(500) COLLATE utf8mb4_unicode_ci NOT NULL DEFAULT '' COMMENT '联系方式（JSON格式：{"email":"","wechat":"","github":""}）',
  `data_retention_policy` text COLLATE utf8mb4_unicode_ci COMMENT '数据保留说明',
  `account_deletion_guide` text COLLATE utf8mb4_unicode_ci COMMENT '账号注销说明',
  `config_version` int unsigned NOT NULL DEFAULT '1' COMMENT '配置版本号',
  `create_time` datetime NOT NULL DEFAULT CURRENT_TIMESTAMP COMMENT '创建时间',
  `update_time` datetime NOT NULL DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP COMMENT '更新时间',
  `created_by` varchar(60) COLLATE utf8mb4_unicode_ci NOT NULL DEFAULT '' COMMENT '创建人',
  `updated_by` varchar(60) COLLATE utf8mb4_unicode_ci NOT NULL DEFAULT '' COMMENT '更新人',
  PRIMARY KEY (`id`),
  CONSTRAINT `chk_compliance_single_row` CHECK ((`id` = 1))
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci COMMENT='博客合规配置表';
/*!40101 SET character_set_client = @saved_cs_client */;

--
-- Table structure for table `t_blog_infrastructure_config`
--

DROP TABLE IF EXISTS `t_blog_infrastructure_config`;
/*!40101 SET @saved_cs_client     = @@character_set_client */;
/*!50503 SET character_set_client = utf8mb4 */;
CREATE TABLE `t_blog_infrastructure_config` (
  `id` tinyint unsigned NOT NULL DEFAULT '1' COMMENT '主键，固定为1',
  `search_engine` varchar(20) COLLATE utf8mb4_unicode_ci NOT NULL DEFAULT 'NONE' COMMENT '搜索引擎: NONE/MEILISEARCH',
  `hot_search_mode` tinyint(1) NOT NULL DEFAULT '0' COMMENT '热搜索模式：0=伪热门(FAKE) 1=真热门(REAL)',
  `hot_search_words` text COLLATE utf8mb4_unicode_ci COMMENT '热搜索词JSON数组',
  `meilisearch_host` varchar(200) COLLATE utf8mb4_unicode_ci NOT NULL DEFAULT '' COMMENT 'MeiliSearch主机地址',
  `meilisearch_api_key` varchar(100) COLLATE utf8mb4_unicode_ci NOT NULL DEFAULT '' COMMENT 'MeiliSearch API Key',
  `meilisearch_index` varchar(100) COLLATE utf8mb4_unicode_ci NOT NULL DEFAULT 'articles' COMMENT 'MeiliSearch索引名称',
  `meilisearch_last_sync_time` datetime DEFAULT NULL COMMENT 'MeiliSearch最后同步时间',
  `recommend_strategy` varchar(20) COLLATE utf8mb4_unicode_ci NOT NULL DEFAULT 'rule' COMMENT '推荐策略：rule/weighted/cf',
  `upload_strategy` varchar(20) COLLATE utf8mb4_unicode_ci NOT NULL DEFAULT 'LOCAL' COMMENT '上传策略：LOCAL/QINIU/ALIYUN_OSS',
  `upload_local_dir` varchar(200) COLLATE utf8mb4_unicode_ci NOT NULL DEFAULT 'uploads' COMMENT '本地上传目录',
  `upload_local_url_prefix` varchar(80) COLLATE utf8mb4_unicode_ci NOT NULL DEFAULT '/uploads/' COMMENT '本地访问前缀',
  `upload_qiniu_bucket` varchar(120) COLLATE utf8mb4_unicode_ci NOT NULL DEFAULT '' COMMENT '七牛Bucket',
  `upload_qiniu_domain` varchar(200) COLLATE utf8mb4_unicode_ci NOT NULL DEFAULT '' COMMENT '七牛访问域名',
  `upload_qiniu_access_key` varchar(120) COLLATE utf8mb4_unicode_ci NOT NULL DEFAULT '' COMMENT '七牛AccessKey',
  `upload_qiniu_secret_key` varchar(120) COLLATE utf8mb4_unicode_ci NOT NULL DEFAULT '' COMMENT '七牛SecretKey',
  `upload_qiniu_region` varchar(20) COLLATE utf8mb4_unicode_ci NOT NULL DEFAULT '' COMMENT '七牛存储区域',
  `upload_aliyun_endpoint` varchar(200) COLLATE utf8mb4_unicode_ci NOT NULL DEFAULT '' COMMENT '阿里云OSS Endpoint',
  `upload_aliyun_bucket` varchar(120) COLLATE utf8mb4_unicode_ci NOT NULL DEFAULT '' COMMENT '阿里云OSS Bucket',
  `upload_aliyun_domain` varchar(200) COLLATE utf8mb4_unicode_ci NOT NULL DEFAULT '' COMMENT '阿里云OSS访问域名',
  `upload_aliyun_access_key` varchar(120) COLLATE utf8mb4_unicode_ci NOT NULL DEFAULT '' COMMENT '阿里云AccessKey',
  `upload_aliyun_secret_key` varchar(120) COLLATE utf8mb4_unicode_ci NOT NULL DEFAULT '' COMMENT '阿里云SecretKey',
  `email_config_json` longtext COLLATE utf8mb4_unicode_ci COMMENT '邮件配置JSON',
  `config_version` int unsigned NOT NULL DEFAULT '1' COMMENT '配置版本号',
  `create_time` datetime NOT NULL DEFAULT CURRENT_TIMESTAMP COMMENT '创建时间',
  `update_time` datetime NOT NULL DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP COMMENT '更新时间',
  `created_by` varchar(60) COLLATE utf8mb4_unicode_ci NOT NULL DEFAULT '' COMMENT '创建人',
  `updated_by` varchar(60) COLLATE utf8mb4_unicode_ci NOT NULL DEFAULT '' COMMENT '更新人',
  `wx_dev_app_id` varchar(100) COLLATE utf8mb4_unicode_ci NOT NULL DEFAULT '' COMMENT '微信小程序开发环境 AppID',
  `wx_dev_app_secret` varchar(200) COLLATE utf8mb4_unicode_ci NOT NULL DEFAULT '' COMMENT '微信小程序开发环境 Secret',
  `wx_prod_app_id` varchar(100) COLLATE utf8mb4_unicode_ci NOT NULL DEFAULT '' COMMENT '微信小程序生产环境 AppID',
  `wx_prod_app_secret` varchar(200) COLLATE utf8mb4_unicode_ci NOT NULL DEFAULT '' COMMENT '微信小程序生产环境 Secret',
  `wx_env_mode` tinyint(1) NOT NULL DEFAULT '0' COMMENT '微信环境模式：0=开发环境 1=生产环境',
  PRIMARY KEY (`id`),
  CONSTRAINT `chk_infrastructure_single_row` CHECK ((`id` = 1))
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci COMMENT='博客基础设施配置表';
/*!40101 SET character_set_client = @saved_cs_client */;

--
-- Table structure for table `t_category`
--

DROP TABLE IF EXISTS `t_category`;
/*!40101 SET @saved_cs_client     = @@character_set_client */;
/*!50503 SET character_set_client = utf8mb4 */;
CREATE TABLE `t_category` (
  `id` bigint unsigned NOT NULL AUTO_INCREMENT COMMENT '分类id',
  `name` varchar(60) CHARACTER SET utf8mb4 COLLATE utf8mb4_unicode_ci NOT NULL DEFAULT '' COMMENT '分类名称',
  `create_time` datetime NOT NULL DEFAULT CURRENT_TIMESTAMP COMMENT '创建时间',
  `update_time` datetime NOT NULL DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP COMMENT '最后一次更新时间',
  `deleted_at` datetime DEFAULT NULL COMMENT '软删除时间',
  `created_by` varchar(60) CHARACTER SET utf8mb4 COLLATE utf8mb4_unicode_ci NOT NULL DEFAULT '' COMMENT '创建人',
  `updated_by` varchar(60) CHARACTER SET utf8mb4 COLLATE utf8mb4_unicode_ci NOT NULL DEFAULT '' COMMENT '更新人',
  PRIMARY KEY (`id`) USING BTREE,
  UNIQUE KEY `uk_name` (`name`) USING BTREE,
  KEY `idx_create_time` (`create_time`) USING BTREE,
  KEY `idx_deleted_at` (`deleted_at`) USING BTREE
) ENGINE=InnoDB AUTO_INCREMENT=10 DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci ROW_FORMAT=DYNAMIC COMMENT='文章分类表';
/*!40101 SET character_set_client = @saved_cs_client */;

--
-- Table structure for table `t_error_log`
--

DROP TABLE IF EXISTS `t_error_log`;
/*!40101 SET @saved_cs_client     = @@character_set_client */;
/*!50503 SET character_set_client = utf8mb4 */;
CREATE TABLE `t_error_log` (
  `id` bigint unsigned NOT NULL AUTO_INCREMENT COMMENT 'id',
  `access_log_id` bigint unsigned NOT NULL DEFAULT '0' COMMENT '访问日志ID',
  `trace_id` varchar(64) CHARACTER SET utf8mb4 COLLATE utf8mb4_unicode_ci NOT NULL DEFAULT '' COMMENT '请求追踪ID',
  `error_code` varchar(100) CHARACTER SET utf8mb4 COLLATE utf8mb4_unicode_ci NOT NULL DEFAULT '' COMMENT '错误码',
  `error_message` varchar(1000) CHARACTER SET utf8mb4 COLLATE utf8mb4_unicode_ci NOT NULL DEFAULT '' COMMENT '错误消息',
  `error_detail` mediumtext CHARACTER SET utf8mb4 COLLATE utf8mb4_unicode_ci COMMENT '错误详情',
  `stack_trace` mediumtext CHARACTER SET utf8mb4 COLLATE utf8mb4_unicode_ci COMMENT '堆栈信息',
  `request_url` varchar(500) CHARACTER SET utf8mb4 COLLATE utf8mb4_unicode_ci NOT NULL DEFAULT '' COMMENT '请求URL',
  `request_method` varchar(12) CHARACTER SET utf8mb4 COLLATE utf8mb4_unicode_ci NOT NULL DEFAULT '' COMMENT '请求方法',
  `request_params` text CHARACTER SET utf8mb4 COLLATE utf8mb4_unicode_ci COMMENT '请求参数',
  `request_body` text CHARACTER SET utf8mb4 COLLATE utf8mb4_unicode_ci COMMENT '请求体',
  `response_body` text CHARACTER SET utf8mb4 COLLATE utf8mb4_unicode_ci COMMENT '响应体',
  `ip_address` varbinary(16) NOT NULL DEFAULT '\0\0' COMMENT 'IP地址',
  `user_agent` varchar(500) CHARACTER SET utf8mb4 COLLATE utf8mb4_unicode_ci NOT NULL DEFAULT '' COMMENT '用户代理',
  `create_time` datetime NOT NULL DEFAULT CURRENT_TIMESTAMP COMMENT '创建时间',
  PRIMARY KEY (`id`) USING BTREE,
  KEY `idx_access_log_id` (`access_log_id`) USING BTREE,
  KEY `idx_trace_id` (`trace_id`) USING BTREE,
  KEY `idx_error_code` (`error_code`) USING BTREE,
  KEY `idx_create_time` (`create_time`) USING BTREE
) ENGINE=InnoDB AUTO_INCREMENT=1344 DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci ROW_FORMAT=DYNAMIC COMMENT='系统错误日志表';
/*!40101 SET character_set_client = @saved_cs_client */;

--
-- Table structure for table `t_link`
--

DROP TABLE IF EXISTS `t_link`;
/*!40101 SET @saved_cs_client     = @@character_set_client */;
/*!50503 SET character_set_client = utf8mb4 */;
CREATE TABLE `t_link` (
  `id` bigint NOT NULL AUTO_INCREMENT COMMENT '主键ID',
  `name` varchar(100) CHARACTER SET utf8mb4 COLLATE utf8mb4_unicode_ci NOT NULL COMMENT '链接名称',
  `url` varchar(500) CHARACTER SET utf8mb4 COLLATE utf8mb4_unicode_ci NOT NULL COMMENT '链接地址',
  `description` varchar(500) CHARACTER SET utf8mb4 COLLATE utf8mb4_unicode_ci DEFAULT '' COMMENT '链接描述',
  `icon` varchar(500) CHARACTER SET utf8mb4 COLLATE utf8mb4_unicode_ci DEFAULT '' COMMENT '图标URL',
  `sort_order` int NOT NULL DEFAULT '0' COMMENT '排序值',
  `is_active` tinyint(1) NOT NULL DEFAULT '1' COMMENT '是否启用',
  `create_time` datetime NOT NULL DEFAULT CURRENT_TIMESTAMP COMMENT '创建时间',
  `update_time` datetime NOT NULL DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP COMMENT '更新时间',
  PRIMARY KEY (`id`),
  UNIQUE KEY `uk_url` (`url`),
  KEY `idx_sort_order` (`sort_order`),
  KEY `idx_is_active` (`is_active`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci COMMENT='友情链接表';
/*!40101 SET character_set_client = @saved_cs_client */;

--
-- Table structure for table `t_mp_browse_history`
--

DROP TABLE IF EXISTS `t_mp_browse_history`;
/*!40101 SET @saved_cs_client     = @@character_set_client */;
/*!50503 SET character_set_client = utf8mb4 */;
CREATE TABLE `t_mp_browse_history` (
  `id` bigint unsigned NOT NULL AUTO_INCREMENT COMMENT '主键',
  `openid` varchar(128) CHARACTER SET utf8mb4 COLLATE utf8mb4_unicode_ci NOT NULL COMMENT '微信OpenID',
  `article_id` bigint unsigned NOT NULL COMMENT '文章ID',
  `create_time` timestamp NOT NULL DEFAULT CURRENT_TIMESTAMP COMMENT '创建时间',
  `update_time` timestamp NOT NULL DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP COMMENT '更新时间',
  PRIMARY KEY (`id`),
  UNIQUE KEY `uk_openid_article` (`openid`,`article_id`),
  KEY `idx_openid` (`openid`),
  KEY `idx_article_id` (`article_id`)
) ENGINE=InnoDB AUTO_INCREMENT=425 DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci COMMENT='小程序浏览历史表';
/*!40101 SET character_set_client = @saved_cs_client */;

--
-- Table structure for table `t_mp_user`
--

DROP TABLE IF EXISTS `t_mp_user`;
/*!40101 SET @saved_cs_client     = @@character_set_client */;
/*!50503 SET character_set_client = utf8mb4 */;
CREATE TABLE `t_mp_user` (
  `id` bigint unsigned NOT NULL AUTO_INCREMENT COMMENT '主键',
  `openid` varchar(64) CHARACTER SET utf8mb4 COLLATE utf8mb4_unicode_ci NOT NULL COMMENT '微信 openid',
  `nickname` varchar(64) CHARACTER SET utf8mb4 COLLATE utf8mb4_unicode_ci NOT NULL DEFAULT '' COMMENT '昵称',
  `avatar` varchar(512) CHARACTER SET utf8mb4 COLLATE utf8mb4_unicode_ci NOT NULL DEFAULT '' COMMENT '头像',
  `status` tinyint(1) NOT NULL DEFAULT '1' COMMENT '状态：1启用 0禁用',
  `first_login_time` datetime NOT NULL DEFAULT CURRENT_TIMESTAMP COMMENT '首次登录时间',
  `last_login_time` datetime NOT NULL DEFAULT CURRENT_TIMESTAMP COMMENT '最近登录时间',
  `create_time` datetime NOT NULL DEFAULT CURRENT_TIMESTAMP COMMENT '创建时间',
  `update_time` datetime NOT NULL DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP COMMENT '更新时间',
  PRIMARY KEY (`id`) USING BTREE,
  UNIQUE KEY `uk_openid` (`openid`) USING BTREE,
  KEY `idx_last_login_time` (`last_login_time`) USING BTREE
) ENGINE=InnoDB AUTO_INCREMENT=206 DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci COMMENT='小程序用户表';
/*!40101 SET character_set_client = @saved_cs_client */;

--
-- Table structure for table `t_mp_user_favorite`
--

DROP TABLE IF EXISTS `t_mp_user_favorite`;
/*!40101 SET @saved_cs_client     = @@character_set_client */;
/*!50503 SET character_set_client = utf8mb4 */;
CREATE TABLE `t_mp_user_favorite` (
  `id` bigint unsigned NOT NULL AUTO_INCREMENT COMMENT '主键',
  `openid` varchar(64) CHARACTER SET utf8mb4 COLLATE utf8mb4_unicode_ci NOT NULL COMMENT '微信 openid',
  `article_id` bigint unsigned NOT NULL COMMENT '文章ID',
  `create_time` datetime NOT NULL DEFAULT CURRENT_TIMESTAMP COMMENT '创建时间',
  `update_time` datetime NOT NULL DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP COMMENT '更新时间',
  PRIMARY KEY (`id`) USING BTREE,
  UNIQUE KEY `uk_openid_article` (`openid`,`article_id`) USING BTREE,
  KEY `idx_openid` (`openid`) USING BTREE,
  KEY `idx_article_id` (`article_id`) USING BTREE,
  CONSTRAINT `fk_mp_favorite_article` FOREIGN KEY (`article_id`) REFERENCES `t_article` (`id`) ON DELETE CASCADE ON UPDATE CASCADE
) ENGINE=InnoDB AUTO_INCREMENT=45 DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci COMMENT='小程序用户收藏表';
/*!40101 SET character_set_client = @saved_cs_client */;

--
-- Table structure for table `t_mp_user_subscribe`
--

DROP TABLE IF EXISTS `t_mp_user_subscribe`;
/*!40101 SET @saved_cs_client     = @@character_set_client */;
/*!50503 SET character_set_client = utf8mb4 */;
CREATE TABLE `t_mp_user_subscribe` (
  `id` bigint unsigned NOT NULL AUTO_INCREMENT,
  `openid` varchar(128) DEFAULT NULL,
  `subscribe` tinyint(1) DEFAULT NULL,
  `create_time` datetime(3) DEFAULT NULL,
  `update_time` datetime(3) DEFAULT NULL,
  PRIMARY KEY (`id`),
  UNIQUE KEY `idx_t_mp_user_subscribe_open_id` (`openid`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_0900_ai_ci;
/*!40101 SET character_set_client = @saved_cs_client */;

--
-- Table structure for table `t_statistics_article_pv`
--

DROP TABLE IF EXISTS `t_statistics_article_pv`;
/*!40101 SET @saved_cs_client     = @@character_set_client */;
/*!50503 SET character_set_client = utf8mb4 */;
CREATE TABLE `t_statistics_article_pv` (
  `article_id` bigint unsigned NOT NULL COMMENT '文章id',
  `pv_date` date NOT NULL COMMENT '被统计的日期',
  `pv_count` bigint unsigned NOT NULL COMMENT 'pv浏览量',
  `create_time` datetime NOT NULL DEFAULT CURRENT_TIMESTAMP COMMENT '创建时间',
  `update_time` datetime NOT NULL DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP COMMENT '最后一次更新时间',
  PRIMARY KEY (`article_id`,`pv_date`) USING BTREE,
  KEY `idx_pv_date` (`pv_date`) USING BTREE,
  CONSTRAINT `fk_pv_article` FOREIGN KEY (`article_id`) REFERENCES `t_article` (`id`) ON DELETE CASCADE ON UPDATE CASCADE
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci ROW_FORMAT=DYNAMIC COMMENT='统计表 - 文章 PV';
/*!40101 SET character_set_client = @saved_cs_client */;

--
-- Table structure for table `t_tag`
--

DROP TABLE IF EXISTS `t_tag`;
/*!40101 SET @saved_cs_client     = @@character_set_client */;
/*!50503 SET character_set_client = utf8mb4 */;
CREATE TABLE `t_tag` (
  `id` bigint unsigned NOT NULL AUTO_INCREMENT COMMENT '标签id',
  `name` varchar(60) CHARACTER SET utf8mb4 COLLATE utf8mb4_unicode_ci NOT NULL DEFAULT '' COMMENT '标签名称',
  `create_time` datetime NOT NULL DEFAULT CURRENT_TIMESTAMP COMMENT '创建时间',
  `update_time` datetime NOT NULL DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP COMMENT '最后一次更新时间',
  `deleted_at` datetime DEFAULT NULL COMMENT '软删除时间',
  `created_by` varchar(60) CHARACTER SET utf8mb4 COLLATE utf8mb4_unicode_ci NOT NULL DEFAULT '' COMMENT '创建人',
  `updated_by` varchar(60) CHARACTER SET utf8mb4 COLLATE utf8mb4_unicode_ci NOT NULL DEFAULT '' COMMENT '更新人',
  PRIMARY KEY (`id`) USING BTREE,
  UNIQUE KEY `uk_name` (`name`) USING BTREE,
  KEY `idx_create_time` (`create_time`) USING BTREE,
  KEY `idx_deleted_at` (`deleted_at`) USING BTREE
) ENGINE=InnoDB AUTO_INCREMENT=16 DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci ROW_FORMAT=DYNAMIC COMMENT='标签表';
/*!40101 SET character_set_client = @saved_cs_client */;

--
-- Table structure for table `t_topic`
--

DROP TABLE IF EXISTS `t_topic`;
/*!40101 SET @saved_cs_client     = @@character_set_client */;
/*!50503 SET character_set_client = utf8mb4 */;
CREATE TABLE `t_topic` (
  `id` bigint unsigned NOT NULL AUTO_INCREMENT COMMENT '专题id',
  `name` varchar(100) CHARACTER SET utf8mb4 COLLATE utf8mb4_unicode_ci NOT NULL COMMENT '专题名称',
  `description` varchar(500) CHARACTER SET utf8mb4 COLLATE utf8mb4_unicode_ci NOT NULL DEFAULT '' COMMENT '专题描述',
  `cover_image` varchar(200) CHARACTER SET utf8mb4 COLLATE utf8mb4_unicode_ci NOT NULL DEFAULT '' COMMENT '专题封面图',
  `is_series` tinyint(1) NOT NULL DEFAULT '0' COMMENT '是否为系列：0否 1是',
  `status` tinyint(1) NOT NULL DEFAULT '1' COMMENT '状态：1启用 0禁用',
  `create_time` datetime NOT NULL DEFAULT CURRENT_TIMESTAMP COMMENT '创建时间',
  `update_time` datetime NOT NULL DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP COMMENT '最后一次更新时间',
  `created_by` varchar(60) CHARACTER SET utf8mb4 COLLATE utf8mb4_unicode_ci NOT NULL DEFAULT '' COMMENT '创建人',
  `updated_by` varchar(60) CHARACTER SET utf8mb4 COLLATE utf8mb4_unicode_ci NOT NULL DEFAULT '' COMMENT '更新人',
  PRIMARY KEY (`id`) USING BTREE,
  UNIQUE KEY `uk_name` (`name`) USING BTREE,
  KEY `idx_create_time` (`create_time`) USING BTREE,
  KEY `idx_status` (`status`) USING BTREE
) ENGINE=InnoDB AUTO_INCREMENT=7 DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci ROW_FORMAT=DYNAMIC COMMENT='专题表';
/*!40101 SET character_set_client = @saved_cs_client */;

--
-- Table structure for table `t_user`
--

DROP TABLE IF EXISTS `t_user`;
/*!40101 SET @saved_cs_client     = @@character_set_client */;
/*!50503 SET character_set_client = utf8mb4 */;
CREATE TABLE `t_user` (
  `id` bigint unsigned NOT NULL AUTO_INCREMENT COMMENT 'id',
  `username` varchar(60) CHARACTER SET utf8mb4 COLLATE utf8mb4_unicode_ci NOT NULL COMMENT '用户名',
  `password_hash` varchar(255) CHARACTER SET utf8mb4 COLLATE utf8mb4_unicode_ci NOT NULL COMMENT '密码哈希',
  `email` varchar(100) CHARACTER SET utf8mb4 COLLATE utf8mb4_unicode_ci NOT NULL COMMENT '邮箱',
  `nickname` varchar(60) CHARACTER SET utf8mb4 COLLATE utf8mb4_unicode_ci NOT NULL DEFAULT '' COMMENT '用户昵称',
  `avatar` varchar(160) CHARACTER SET utf8mb4 COLLATE utf8mb4_unicode_ci NOT NULL DEFAULT '' COMMENT '用户头像',
  `status` varchar(20) CHARACTER SET utf8mb4 COLLATE utf8mb4_unicode_ci NOT NULL DEFAULT 'ENABLED' COMMENT '用户状态：ENABLED/DISABLED',
  `last_login_time` datetime DEFAULT NULL COMMENT '最后登录时间',
  `last_login_ip` varchar(45) CHARACTER SET utf8mb4 COLLATE utf8mb4_unicode_ci NOT NULL DEFAULT '' COMMENT '最后登录IP',
  `login_failure_count` int unsigned NOT NULL DEFAULT '0' COMMENT '登录失败次数',
  `locked_until` datetime DEFAULT NULL COMMENT '账户锁定时间',
  `create_time` datetime NOT NULL DEFAULT CURRENT_TIMESTAMP COMMENT '创建时间',
  `update_time` datetime NOT NULL DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP COMMENT '最后一次更新时间',
  `created_by` varchar(60) CHARACTER SET utf8mb4 COLLATE utf8mb4_unicode_ci NOT NULL DEFAULT '' COMMENT '创建人',
  `updated_by` varchar(60) CHARACTER SET utf8mb4 COLLATE utf8mb4_unicode_ci NOT NULL DEFAULT '' COMMENT '更新人',
  `is_admin` tinyint(1) NOT NULL DEFAULT '0' COMMENT '是否管理员：0否 1是',
  PRIMARY KEY (`id`) USING BTREE,
  KEY `idx_create_time` (`create_time`) USING BTREE,
  KEY `idx_username` (`username`) USING BTREE,
  KEY `idx_email` (`email`) USING BTREE
) ENGINE=InnoDB AUTO_INCREMENT=3 DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci ROW_FORMAT=DYNAMIC COMMENT='用户表';
/*!40101 SET character_set_client = @saved_cs_client */;
/*!40103 SET TIME_ZONE=@OLD_TIME_ZONE */;

/*!40101 SET SQL_MODE=@OLD_SQL_MODE */;
/*!40014 SET FOREIGN_KEY_CHECKS=@OLD_FOREIGN_KEY_CHECKS */;
/*!40014 SET UNIQUE_CHECKS=@OLD_UNIQUE_CHECKS */;
/*!40101 SET CHARACTER_SET_CLIENT=@OLD_CHARACTER_SET_CLIENT */;
/*!40101 SET CHARACTER_SET_RESULTS=@OLD_CHARACTER_SET_RESULTS */;
/*!40101 SET COLLATION_CONNECTION=@OLD_COLLATION_CONNECTION */;
/*!40111 SET SQL_NOTES=@OLD_SQL_NOTES */;

-- Dump completed on 2026-07-17  0:53:06
