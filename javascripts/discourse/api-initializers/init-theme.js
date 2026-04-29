import { apiInitializer } from "discourse/lib/api";

export default apiInitializer("1.34", (api) => {
  const user = api.getCurrentUser();
  if (!user) return;

  const ignoredUsers = user.ignored_users || [];
  if (ignoredUsers.length === 0) return;

  const ignoredUsersLower = ignoredUsers.map(u => u.toLowerCase());
  const topicCreatorCache = new Map();

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

  // Para lista de tópicos recentes
  async function hideIgnoredTopicsInLatestList() {
    const latestItems = document.querySelectorAll(".latest-topic-list-item:not([data-v0-processed])");

    // Processa todos em paralelo para ser mais rápido
    const promises = Array.from(latestItems).map(async (item) => {
      item.setAttribute("data-v0-processed", "true");

      const topicId = item.getAttribute("data-topic-id");
      if (!topicId) return;

      let creatorUsername = topicCreatorCache.get(topicId);

      if (!creatorUsername) {
        try {
          const response = await fetch(`/t/${topicId}.json`);
          const data = await response.json();
          creatorUsername = data.details?.created_by?.username;
          if (creatorUsername) {
            topicCreatorCache.set(topicId, creatorUsername);
          }
        } catch (e) {
          return;
        }
      }

      if (creatorUsername && ignoredUsersLower.includes(creatorUsername.toLowerCase())) {
        item.style.display = "none";
      }
    });

    await Promise.all(promises);
  }

  api.onPageChange(() => {
    hideIgnoredTopicsInLatestList();
  });
});
