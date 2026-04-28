import { apiInitializer } from "discourse/lib/api";

export default apiInitializer("1.34", (api) => {
  const user = api.getCurrentUser();
  if (!user) return;

  const ignoredUsers = user.ignored_usernames || user.ignored_users || [];
  if (ignoredUsers.length === 0) return;

  // 1. Para tabela de tópicos tradicional (funciona com transformer)
  api.registerValueTransformer(
    "topic-list-item-class",
    ({ value, context: { topic } }) => {
      if (
        topic?.creator &&
        ignoredUsers.includes(topic.creator.username)
      ) {
        value.push("hidden-topic");
      }
      return value;
    }
  );

  // 2. Para lista de tópicos recentes (usa MutationObserver)
  function hideIgnoredTopicsInLatestList() {
    const latestItems = document.querySelectorAll(".latest-topic-list-item:not([data-ignore-checked])");
    
    latestItems.forEach((item) => {
      item.setAttribute("data-ignore-checked", "true");
      
      const userCard = item.querySelector(".topic-poster a[data-user-card]");
      if (userCard) {
        const username = userCard.getAttribute("data-user-card");
        if (username && ignoredUsers.some(u => u.toLowerCase() === username.toLowerCase())) {
          item.style.display = "none";
        }
      }
    });
  }

  // Executa no carregamento inicial
  api.onPageChange(() => {
    hideIgnoredTopicsInLatestList();
  });

  // Observa mudanças dinâmicas (infinite scroll, etc.)
  const observer = new MutationObserver(() => {
    hideIgnoredTopicsInLatestList();
  });

  api.onAppEvent("page:changed", () => {
    const latestList = document.querySelector(".latest-topic-list");
    if (latestList) {
      observer.observe(latestList, { childList: true, subtree: true });
    }
    hideIgnoredTopicsInLatestList();
  });
});
