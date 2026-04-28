import { apiInitializer } from "discourse/lib/api";

export default apiInitializer("1.34", (api) => {
  // Get theme settings
  const hideAvatar = settings.hide_ignored_users_avatar;
  const hideTopics = settings.hide_ignored_user_topics;

  // If both settings are disabled, bail
  if (!hideAvatar && !hideTopics) {
    return;
  }

  // get current user
  const user = api.getCurrentUser();

  // not logged in, bail
  if (!user) {
    return;
  }

  // get a list of ignored users
  const ignoredUsers = user.ignored_users;

  if (!ignoredUsers?.length) {
    return;
  }

  // Helper function to check if a user is ignored
  function isIgnoredUser(username) {
    return ignoredUsers.includes(username);
  }

  // Helper function to check if topic creator is ignored
  function isIgnoredTopicCreator(topic) {
    // Try multiple ways to get the topic creator username
    const posters = topic.posters;
    if (posters && posters.length > 0) {
      const topicCreator = posters[0];
      const username = topicCreator?.user?.username || topicCreator?.username;
      if (username) {
        return isIgnoredUser(username);
      }
    }

    // Fallback: check topic.creator or topic.user
    const creatorUsername = topic.creator?.username || topic.user?.username;
    if (creatorUsername) {
      return isIgnoredUser(creatorUsername);
    }

    return false;
  }

  // Helper function to check if any poster is ignored (for avatar hiding)
  function getIgnoredPosterUsernames(topic) {
    const ignoredPosters = [];
    const posters = topic.posters;

    if (posters && posters.length > 0) {
      posters.forEach((poster) => {
        const username = poster?.user?.username || poster?.username;
        if (username && isIgnoredUser(username)) {
          ignoredPosters.push(username);
        }
      });
    }

    return ignoredPosters;
  }

  // Use the new topic-list-item-class transformer to add classes
  api.registerValueTransformer("topic-list-item-class", ({ value, context }) => {
    const { topic } = context;

    if (!topic) {
      return value;
    }

    // Hide topics created by ignored users (if setting enabled)
    if (hideTopics && isIgnoredTopicCreator(topic)) {
      value.push("ignored-op-topic");
    }

    // Mark topics that have ignored posters for avatar hiding (if setting enabled)
    if (hideAvatar) {
      const ignoredPosters = getIgnoredPosterUsernames(topic);
      if (ignoredPosters.length > 0) {
        value.push("has-ignored-posters");

        // Add class with ignored usernames for CSS targeting
        ignoredPosters.forEach((username) => {
          value.push(`ignored-poster-${username.toLowerCase()}`);
        });
      }
    }

    return value;
  });

  // Use topic-list-class transformer for list-level classes
  api.registerValueTransformer("topic-list-class", ({ value }) => {
    value.push("ignore-plus-enabled");
    return value;
  });
});
