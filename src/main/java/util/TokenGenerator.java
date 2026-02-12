package util;

import dao.TokenDao;
import model.Token;

import java.sql.Timestamp;
import java.util.UUID;

public class TokenGenerator {
    public static String generateAndInsertToken() throws Exception {
        TokenDao dao = new TokenDao();
        Token token = new Token();
        token.setToken(UUID.randomUUID().toString());
        token.setDateExpiration(new Timestamp(System.currentTimeMillis() + 24 * 60 * 60 * 1000));
        dao.insert(token);
        return token.getToken();
    }

    public static void main(String[] args) throws Exception {
        String token = generateAndInsertToken();
        System.out.println("Token généré : " + token);
    }
}