import { apiInitializer } from "discourse/lib/api";

export default apiInitializer("1.34", (api) => {
  const currentUser = api.getCurrentUser();
  if (!currentUser) return;

  api.registerValueTransformer(
    "topic-list-item-class",
    ({ value, context }) => {
      const topic = context?.topic;
      if (!topic) return value;

      // O autor do tópico geralmente está em topic.posters[0] ou topic.creator
      // Vamos verificar ambos
      const topicCreatorUsername = 
        topic.creator?.username || 
        topic.posters?.[0]?.user?.username ||
        topic.details?.created_by?.username;

      // Verifica se o criador está na lista de ignorados
      const ignoredUsers = currentUser.ignored_usernames || currentUser.ignored_users || [];
      
      if (topicCreatorUsername && ignoredUsers.includes(topicCreatorUsername)) {
        value.push("hidden");
      }

      return value;
    }
  );
});
