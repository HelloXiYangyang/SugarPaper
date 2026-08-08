<template>
  <footer class="fluent-footer">
    <div class="fluent-footer__content">
      <div class="fluent-footer__text">
        &copy; 2026-{{ new Date().getFullYear() }} 糖纸 · SugarPaper · GNU AGPL-3.0 开源协议 · 离线优先 · 零服务器依赖
      </div>
      <div class="fluent-footer__text">
        Build_{{ gitTag }}
      </div>

      <div class="fluent-footer__social">
        <a
          v-for="item in items"
          :key="item.title"
          :href="item.href"
          :title="item.title"
          class="fluent-footer__social-link"
          rel="noopener noreferrer"
          target="_blank"
        >
          <FluentSystemIcon :name="item.icon" :size="16" />
        </a>
      </div>
    </div>
  </footer>
</template>

<script setup lang="ts">
import FluentSystemIcon from './FluentSystemIcon.vue';

const items = [
  {
    title: 'GitHub 仓库',
    icon: 'github',
    href: 'https://github.com/HelloXiYangyang/SugarPaper'
  },
  {
    title: 'Releases',
    icon: 'arrowDownload',
    href: 'https://github.com/HelloXiYangyang/SugarPaper/releases'
  },
  {
    title: '反馈问题',
    icon: 'chat',
    href: 'https://github.com/HelloXiYangyang/SugarPaper/issues'
  }
];
const gitTag = __GIT_TAG__;

</script>

<style scoped lang="scss">
.fluent-footer {
  /* Removed position absolute, relying on flex layout in parent */
  background: var(--background-fill-color-solid-background-base);
  padding: 24px;
  border-top: 1px solid var(--stroke-color-surface-stroke-default);
  font-family: var(--font-family-base);
  font-size: 12px;
  color: var(--fill-color-text-secondary);
  width: 100%;

  &__content {
    display: flex;
    flex-wrap: wrap;
    gap: 16px;
    align-items: center;
    max-width: 1200px;
    margin: 0 auto;
  }

  &__text {
    color: inherit;
  }

  &__link {
    color: inherit;
    text-decoration: none;
    &:hover {
      text-decoration: underline;
      color: var(--fill-color-text-primary);
    }
  }

  &__social {
    margin-left: auto;
    display: flex;
    gap: 12px;
  }

  &__social-link {
    color: inherit;
    text-decoration: none;
    display: flex;
    align-items: center;
    justify-content: center;
    width: 24px;
    height: 24px;
    border-radius: 4px;
    transition: background 0.2s, color 0.2s;

    &:hover {
      background: var(--fill-color-control-alt-secondary);
      color: var(--fill-color-accent-default);
    }
  }
}
</style>
