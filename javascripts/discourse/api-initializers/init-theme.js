import { apiInitializer } from "discourse/lib/api";

export default apiInitializer("1.34", (api) => {
  const user = api.getCurrentUser();
  if (!user) return;

  const ignoredUsers = user.ignored_users || [];
  if (ignoredUsers.length === 0) return;

  // Converte para lowercase para comparação
  const ignoredUsersLower = ignoredUsers.map(u => u.toLowerCase());

  // Para tabela de tópicos tradicional
  api.registerValueTransformer(
    "topic-list-item-class",
    ({ value, context: { topic } }) => {
      if (
        topic?.creator &&
        ignoredUsersLower.includes(topic.creator.username.toLowerCase())
      ) {
        value.push("hidden-topic");
      }
      return value;
    }
  );

  // Para lista de tópicos recentes - busca o criador real via store
  function hideIgnoredTopicsInLatestList() {
    const topicStore = api.container.lookup("service:store");
    const latestItems = document.querySelectorAll(".latest-topic-list-item:not([data-v0-processed])");

    latestItems.forEach((item) => {
      item.setAttribute("data-v0-processed", "true");

      const topicId = item.getAttribute("data-topic-id");
      if (!topicId) return;

      // Busca o tópico no store do Discourse
      const topic = topicStore.peekRecord("topic", topicId);
      
      if (topic) {
        // O criador está em topic.creator ou topic.posters[0] dependendo da versão
        const creatorUsername = 
          topic.creator?.username || 
          topic.details?.created_by?.username ||
          topic.posters?.find(p => p.description?.includes("Original"))?.user?.username;

        if (creatorUsername && ignoredUsersLower.includes(creatorUsername.toLowerCase())) {
          item.style.display = "none";
        }
      }
    });
  }

  api.onPageChange(() => {
    setTimeout(hideIgnoredTopicsInLatestList, 300);
  });

  // Observer para infinite scroll
  const observer = new MutationObserver(() => {
    hideIgnoredTopicsInLatestList();
  });

  document.addEventListener("DOMContentLoaded", () => {
    const latestList = document.querySelector(".latest-topic-list");
    if (latestList) {
      observer.observe(latestList, { childList: true, subtree: true });
    }
  });
});
