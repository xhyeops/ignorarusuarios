import { apiInitializer } from "discourse/lib/api";

export default apiInitializer("1.34", (api) => {
  const hideAvatar = settings.hide_ignored_users_avatar;
  const hideTopics = settings.hide_ignored_user_topics;

  if (!hideAvatar && !hideTopics) return;

  const user = api.getCurrentUser();
  if (!user) return;

  const ignoredUsers = user.ignored_users || [];
  if (!ignoredUsers.length) return;

  function normalize(username) {
    return username?.toString?.().toLowerCase().trim();
  }

  function isIgnoredUser(username) {
    return ignoredUsers.some((ignored) => normalize(ignored) === normalize(username));
  }

  function getUsername(poster) {
    return poster?.user?.username || poster?.username;
  }

  function isIgnoredTopicCreator(topic) {
    const posters = topic.posters || [];
    const username = getUsername(posters[0]);

    if (username) return isIgnoredUser(username);

    const creatorUsername = topic.creator?.username || topic.user?.username;
    if (creatorUsername) return isIgnoredUser(creatorUsername);

    return false;
  }

  function isLatestPosterIgnored(topic) {
    const posters = topic.posters || [];

    return posters.some((poster) => {
      const username = getUsername(poster);
      const description = poster?.description?.toLowerCase?.() || "";

      const isLatest =
        poster?.extras === "latest" ||
        description.includes("most recent") ||
        description.includes("último") ||
        description.includes("mais recente");

      return username && isLatest && isIgnoredUser(username);
    });
  }

  api.registerValueTransformer("topic-list-item-class", ({ value, context }) => {
    const topic = context?.topic;
    if (!topic) return value;

    if (hideTopics && isIgnoredTopicCreator(topic)) {
      value.push("ignored-op-topic");
    }

    if (hideAvatar && isLatestPosterIgnored(topic)) {
      value.push("ignored-latest-poster");
    }

    return value;
  });

  api.registerValueTransformer("topic-list-class", ({ value }) => {
    value.push("ignore-plus-enabled");
    return value;
  });
});
