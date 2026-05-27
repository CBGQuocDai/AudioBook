package org.backend.config;

import org.springframework.context.annotation.Bean;
import org.springframework.context.annotation.Configuration;
import org.springframework.data.redis.connection.RedisConnectionFactory;
import org.springframework.data.redis.core.RedisTemplate;
import org.springframework.data.redis.serializer.GenericJackson2JsonRedisSerializer;
import org.springframework.data.redis.serializer.StringRedisSerializer;

/**
 * Configuration class for Redis operations.
 * Sets up the connection factory and serializers for Redis templates.
 */
@Configuration
public class RedisConfig {
    /**
     * Configures and provides a {@link RedisTemplate} for database interactions.
     * Uses {@link StringRedisSerializer} for keys and {@link GenericJackson2JsonRedisSerializer} for values.
     *
     * @param connectionFactory the factory to establish Redis connections
     * @return the configured {@link RedisTemplate} instance
     */
    @Bean
    public RedisTemplate<String, Object> redisTemplate(RedisConnectionFactory connectionFactory) {
        RedisTemplate<String, Object> template = new RedisTemplate<>();
        template.setConnectionFactory(connectionFactory);

        // key serializer
        template.setKeySerializer(new StringRedisSerializer());

        // value serializer (JSON)
        template.setValueSerializer(new GenericJackson2JsonRedisSerializer());

        return template;
    }
}