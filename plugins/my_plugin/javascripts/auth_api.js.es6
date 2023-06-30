import { ajax } from 'discourse/lib/ajax';

export default {
  register(name, email, password) {
    return ajax('/my_plugin/register', {
      type: 'POST',
      dataType: 'json',
      data: {
        name,
        email,
        password
      }
    });
  },
  
  authenticate(email, password) {
    return ajax('/my_plugin/authenticate', {
      type: 'POST',
      dataType: 'json',
      data: {
        email,
        password
      }
    });
  }
};
